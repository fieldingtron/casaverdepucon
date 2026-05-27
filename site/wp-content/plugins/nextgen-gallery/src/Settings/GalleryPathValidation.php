<?php
/**
 * Shared validation for the gallery storage path (relative to the galleries document root).
 *
 * @package Imagely\NGG\Settings
 */

namespace Imagely\NGG\Settings;

use Imagely\NGG\Util\Filesystem;
use WP_Error;

/**
 * Validates user-provided gallerypath strings for saves and REST updates.
 */
class GalleryPathValidation {

	/**
	 * @param mixed $gallerypath Raw value (typically string from form or JSON).
	 * @return true|\WP_Error True if the path is a safe relative path under the galleries root.
	 */
	public static function validate_relative_under_galleries_root( $gallerypath ) {
		if ( ! is_string( $gallerypath ) ) {
			return new WP_Error(
				'invalid_gallerypath',
				__( 'Gallery path must be a string.', 'nggallery' )
			);
		}
		$trimmed = trim( $gallerypath );
		if ( '' === $trimmed ) {
			return new WP_Error(
				'invalid_gallerypath',
				__( 'Gallery path must be a non-empty relative path.', 'nggallery' )
			);
		}

		$fs       = Filesystem::get_instance();
		$root     = wp_normalize_path( $fs->get_document_root( 'galleries' ) );
		$relative = $fs->add_trailing_slash( $trimmed );
		$sections = explode( '/', str_replace( '\\', '/', trim( $relative, '/\\' ) ) );
		if ( in_array( '..', $sections, true ) ) {
			return new WP_Error(
				'invalid_gallerypath',
				__( "Gallery paths may not use '..' to access parent directories.", 'nggallery' )
			);
		}

		$gallery_abspath = wp_normalize_path( path_join( $root, $relative ) );
		$root_normalized = wp_normalize_path( $root );
		$root_prefixed   = trailingslashit( $root_normalized );
		// PHP 7.4: avoid str_starts_with() (PHP 8+).
		$under_root      = ( $gallery_abspath === $root_normalized )
			|| (
				strlen( $gallery_abspath ) >= strlen( $root_prefixed )
				&& 0 === strpos( $gallery_abspath, $root_prefixed )
			);
		if ( ! $under_root ) {
			return new WP_Error(
				'invalid_gallerypath',
				sprintf(
					/* translators: %s: galleries root directory path */
					__( 'Gallery path must be located under %s', 'nggallery' ),
					$root_normalized
				)
			);
		}

		return true;
	}
}
