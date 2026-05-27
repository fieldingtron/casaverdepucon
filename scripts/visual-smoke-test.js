#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const target = process.env.CVP_TEST_URL || 'http://localhost:8083';
const outDir = process.env.CVP_SCREENSHOT_DIR || path.join(process.cwd(), 'artifacts', 'visual-smoke');

const pages = [
	['home', '/'],
	['contact', '/contacto/'],
	['gallery', '/fotos/'],
	['project', '/casa-azocar/'],
	['login', '/wp-login.php'],
];

const viewports = [
	['mobile', 390, 844],
	['desktop', 1366, 900],
];

function absoluteUrl(pagePath) {
	return new URL(pagePath, target).toString();
}

function safeName(value) {
	return value.replace(/[^a-z0-9]+/gi, '-').replace(/^-|-$/g, '').toLowerCase();
}

(async () => {
	fs.mkdirSync(outDir, { recursive: true });

	const browser = await chromium.launch({ headless: true });
	const results = [];

	for (const [pageName, pagePath] of pages) {
		for (const [viewportName, width, height] of viewports) {
			const page = await browser.newPage({ viewport: { width, height } });
			const consoleErrors = [];

			page.on('console', (message) => {
				if (message.type() === 'error') {
					consoleErrors.push(message.text());
				}
			});

			const response = await page.goto(absoluteUrl(pagePath), {
				waitUntil: 'networkidle',
				timeout: 60000,
			});

			await page.evaluate(async () => {
				const step = Math.max(window.innerHeight - 100, 300);
				for (let y = 0; y < document.body.scrollHeight; y += step) {
					window.scrollTo(0, y);
					await new Promise((resolve) => setTimeout(resolve, 75));
				}
				window.scrollTo(0, 0);
			});
			await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});

			const metrics = await page.evaluate(() => {
				const doc = document.documentElement;
				const images = Array.from(document.images);
				const visibleImages = images.filter((img) => {
					const rect = img.getBoundingClientRect();
					return rect.width > 1 && rect.height > 1;
				});
				const brokenImages = visibleImages
					.filter((img) => !img.complete || img.naturalWidth === 0)
					.map((img) => img.currentSrc || img.src);

				return {
					title: document.title,
					clientWidth: doc.clientWidth,
					scrollWidth: doc.scrollWidth,
					visibleImages: visibleImages.length,
					brokenImages: brokenImages.length,
					brokenImageUrls: brokenImages.slice(0, 10),
					hasHorizontalOverflow: doc.scrollWidth > doc.clientWidth + 1,
				};
			});

			const screenshot = path.join(outDir, `${safeName(pageName)}-${safeName(viewportName)}.png`);
			await page.screenshot({ path: screenshot, fullPage: true });

			const pass =
				response &&
				response.ok() &&
				!metrics.hasHorizontalOverflow &&
				metrics.brokenImages === 0 &&
				consoleErrors.length === 0;

			results.push({
				pageName,
				pagePath,
				viewportName,
				status: response ? response.status() : 0,
				pass,
				screenshot,
				consoleErrors,
				...metrics,
			});

			await page.close();
		}
	}

	await browser.close();

	for (const result of results) {
		const status = result.pass ? 'PASS' : 'FAIL';
		console.log(
			`${status} ${result.pageName} ${result.viewportName} ` +
				`http=${result.status} scroll=${result.scrollWidth}/${result.clientWidth} ` +
				`images=${result.visibleImages} broken=${result.brokenImages} screenshot=${result.screenshot}`
		);
	}

	const failures = results.filter((result) => !result.pass);
	if (failures.length) {
		console.error(`\n${failures.length} visual smoke checks failed.`);
		for (const failure of failures) {
			if (failure.brokenImageUrls.length) {
				console.error(`${failure.pageName} ${failure.viewportName} broken images:`);
				for (const imageUrl of failure.brokenImageUrls) {
					console.error(`- ${imageUrl}`);
				}
			}
			if (failure.consoleErrors.length) {
				console.error(`${failure.pageName} ${failure.viewportName} console errors:`);
				for (const error of failure.consoleErrors.slice(0, 5)) {
					console.error(`- ${error}`);
				}
			}
		}
		process.exit(1);
	}

	console.log(`\n${results.length} visual smoke checks passed for ${target}.`);
})();
