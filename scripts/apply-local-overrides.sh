#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WP="$PROJECT_DIR/scripts/wp.sh"

"$WP" theme activate cvp-twentyten >/dev/null
"$WP" eval '
$url = home_url("/wp-content/themes/twentyten/images/headers/forestfloor.jpg");
set_theme_mod("header_image", $url);
set_theme_mod("header_image_data", (object) array(
	"url" => $url,
	"thumbnail_url" => $url,
	"height" => 198,
	"width" => 940,
));
' >/dev/null
"$WP" plugin deactivate wp-smushit contact-form-plugin si-contact-form wordfence wps-hide-login wp-2fa >/dev/null || true
"$WP" plugin delete contact-form-plugin si-contact-form wordfence wp-smushit >/dev/null || true
"$WP" plugin install ewww-image-optimizer limit-login-attempts-reloaded query-monitor --activate >/dev/null
"$WP" plugin activate akismet all-in-one-seo-pack dreamhost-panel-login imsanity ml-slider nextgen-gallery sucuri-scanner updraftplus >/dev/null

"$WP" post update 52 --post_content='<p style="text-align: justify;"><span style="text-align: justify;">&nbsp;Cualquier consulta o petición de un presupuesto no dude en escribirnos a <span style="color: #3366ff;">arquimasde@gmail.com&nbsp; &nbsp;&nbsp;</span></span></p>
<p style="text-align: justify;">Para nosotos la&nbsp;forma de contacto más personal y enriquecedora es concretar una reunión a través de los teléfonos <span style="color: #000000;"><b>+569 92819948&nbsp; +569 64045797</b></span></p>' >/dev/null

"$WP" eval '
$menu_name = "Primary";
$menu = wp_get_nav_menu_object($menu_name);
$menu_id = $menu ? (int) $menu->term_id : wp_create_nav_menu($menu_name);

foreach (wp_get_nav_menu_items($menu_id) ?: [] as $item) {
	wp_delete_post($item->ID, true);
}

$excluded = array(127);
$add_pages = function ($parent_page_id, $parent_menu_item_id) use (&$add_pages, $menu_id, $excluded) {
	$pages = get_pages(array(
		"parent" => $parent_page_id,
		"post_status" => "publish",
		"sort_column" => "menu_order,post_title",
		"sort_order" => "ASC",
	));

	foreach ($pages as $page) {
		if (in_array((int) $page->ID, $excluded, true)) {
			continue;
		}

		$title = (int) $page->ID === 21 ? "Inicio" : $page->post_title;
		$menu_item_id = wp_update_nav_menu_item($menu_id, 0, array(
			"menu-item-object-id" => $page->ID,
			"menu-item-object" => "page",
			"menu-item-title" => $title,
			"menu-item-type" => "post_type",
			"menu-item-status" => "publish",
			"menu-item-parent-id" => $parent_menu_item_id,
		));

		if (!is_wp_error($menu_item_id)) {
			$add_pages((int) $page->ID, (int) $menu_item_id);
		}
	}
};

$add_pages(0, 0);
$locations = get_theme_mod("nav_menu_locations", array());
$locations["primary"] = $menu_id;
set_theme_mod("nav_menu_locations", $locations);
' >/dev/null

"$WP" rewrite flush >/dev/null || true

"$PROJECT_DIR/scripts/optimize-db.sh"

echo "Applied local CVP overrides."
