<?php
/**
 * CVP child theme setup.
 */

add_action(
	'wp_enqueue_scripts',
	function () {
		wp_enqueue_style(
			'twentyten-parent',
			get_template_directory_uri() . '/style.css',
			array(),
			wp_get_theme( 'twentyten' )->get( 'Version' )
		);

		wp_enqueue_style(
			'cvp-twentyten',
			get_stylesheet_uri(),
			array( 'twentyten-parent' ),
			wp_get_theme()->get( 'Version' )
		);
	}
);
