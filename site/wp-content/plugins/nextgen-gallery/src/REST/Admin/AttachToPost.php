<?php

namespace Imagely\NGG\REST\Admin;

use Imagely\NGG\DataMappers\Album as AlbumMapper;
use Imagely\NGG\DataMappers\Gallery as GalleryMapper;
use Imagely\NGG\DataMappers\Image as ImageMapper;
use Imagely\NGG\DataStorage\Manager as StorageManager;
use Imagely\NGG\DataTypes\DisplayedGallery;

/**
 * REST API controller for Attach to Post functionality.
 */
class AttachToPost extends \WP_REST_Controller {

	public function __construct() {
		$this->namespace = 'ngg/v1';
		$this->rest_base = 'admin/attach_to_post/';
	}

	public function register_routes() {
		\register_rest_route(
			$this->namespace,
			'/' . $this->rest_base . 'galleries',
			[
				[
					'methods'             => \WP_REST_Server::ALLMETHODS,
					'callback'            => [ $this, 'get_galleries' ],
					'permission_callback' => [ $this, 'get_items_permissions_check' ],
				],
			]
		);
		\register_rest_route(
			$this->namespace,
			'/' . $this->rest_base . 'albums',
			[
				[
					'methods'             => \WP_REST_Server::ALLMETHODS,
					'callback'            => [ $this, 'get_albums' ],
					'permission_callback' => [ $this, 'get_items_permissions_check' ],
				],
			]
		);
		\register_rest_route(
			$this->namespace,
			'/' . $this->rest_base . 'tags',
			[
				[
					'methods'             => \WP_REST_Server::ALLMETHODS,
					'callback'            => [ $this, 'get_tags' ],
					'permission_callback' => [ $this, 'get_items_permissions_check' ],
				],
			]
		);
		\register_rest_route(
			$this->namespace,
			'/' . $this->rest_base . 'images',
			[
				[
					'methods'             => \WP_REST_Server::ALLMETHODS,
					'callback'            => [ $this, 'get_images' ],
					'permission_callback' => [ $this, 'get_items_permissions_check' ],
				],
			]
		);
	}

	public function get_items_permissions_check( $request ) {
  // phpcs:ignore WordPress.WP.Capabilities.Unknown
		return current_user_can( 'NextGEN Attach Interface' );
	}

	public function get_galleries( $request ) {
		$galleries    = GalleryMapper::get_instance()->find_all();
		$storage      = StorageManager::get_instance();
		$image_mapper = ImageMapper::get_instance();

		// Enhance each gallery with preview image URL and image count
		foreach ( $galleries as &$gallery ) {
			// Add image count - use ImageMapper's find_all_for_gallery method
			$images               = $image_mapper->find_all_for_gallery( $gallery->gid, false );
			$gallery->image_count = is_array( $images ) ? count( $images ) : 0;

			// Add preview image URL if preview pic exists
			if ( $gallery->previewpic && $gallery->previewpic > 0 ) {
				$preview_image = $image_mapper->find( $gallery->previewpic );
				if ( $preview_image ) {
					$gallery->previewpic_image_url = $storage->get_image_url( $preview_image, 'thumb', true );
				}
			}
		}

		return new \WP_REST_Response(
			[
				'items' => $galleries,
			]
		);
	}

	public function get_albums( $request ) {
		return new \WP_REST_Response(
			[
				'items' => AlbumMapper::get_instance()->find_all(),
			]
		);
	}

	public function get_tags( $request ) {
		$response = [];

		$response['items'] = [];
		$params            = [ 'fields' => 'names' ];
		foreach ( \get_terms( array_merge( [ 'taxonomy' => 'ngg_tag' ], $params ) ) as $term ) {
			$response['items'][] = [
				'id'    => $term,
				'title' => $term,
				'name'  => $term,
			];
		}

		return new \WP_REST_Response( $response );
	}

	public function get_images( $request ) {
		$response = [];

		$params = $request->get_param( 'displayed_gallery' );
		if ( ! is_array( $params ) ) {
			$params = [];
		}

		$storage      = StorageManager::get_instance();
		$image_mapper = ImageMapper::get_instance();

		$displayed_gallery = new DisplayedGallery();

		// Per-property allowlist + type cast for DisplayedGallery params arriving from the REST body.
		// Anything outside the allowlist is silently dropped; values are cast per group rather than
		// piped through esc_sql() (which is not a substitute for $wpdb->prepare()).
		// sortorder belongs with the ID arrays: it is the user's drag-and-drop order, a list of pids.
		// Classifying it as a string ran every array payload through is_scalar() and coerced it to '',
		// wiping the custom order so the modal reopened with the default gallery sort.
		$id_array_props = [ 'container_ids', 'entity_ids', 'excluded_container_ids', 'gallery_ids', 'image_ids', 'tag_ids', 'album_ids', 'ids', 'exclusions', 'sortorder' ];
		$string_props   = [ 'display_type', 'order_by', 'order_direction', 'returns', 'source', 'src', 'slug', 'transient_id' ];
		$int_props      = [ 'ID', 'id', 'maximum_entity_count', 'images_list_count' ];
		$bool_props     = [ 'is_album_gallery', 'skip_excluding_globally_excluded_images', 'tagcloud' ];
		$assoc_props    = [ 'display_settings' ];
		$text_props     = [ 'effect_code', 'inner_content', 'display' ];

		foreach ( $params as $raw_key => $raw_value ) {
			if ( ! is_string( $raw_key ) ) {
				continue;
			}
			$key = sanitize_key( $raw_key );
			if ( '' === $key ) {
				continue;
			}

			if ( in_array( $key, $id_array_props, true ) ) {
				if ( is_array( $raw_value ) ) {
					$value = array_values( array_filter( array_map( 'absint', $raw_value ) ) );
				} elseif ( is_string( $raw_value ) ) {
					$value = array_values(
						array_filter(
							array_map(
								'absint',
								array_map( 'trim', explode( ',', $raw_value ) )
							)
						)
					);
				} else {
					$value = [];
				}
			} elseif ( in_array( $key, $string_props, true ) ) {
				$value = is_scalar( $raw_value ) ? sanitize_text_field( (string) $raw_value ) : '';
			} elseif ( in_array( $key, $int_props, true ) ) {
				$value = is_scalar( $raw_value ) ? (int) $raw_value : 0;
			} elseif ( in_array( $key, $bool_props, true ) ) {
				$value = (bool) $raw_value;
			} elseif ( in_array( $key, $assoc_props, true ) ) {
				if ( is_array( $raw_value ) ) {
					$value = $raw_value;
				} elseif ( is_string( $raw_value ) ) {
					$decoded = json_decode( $raw_value, true );
					$value   = is_array( $decoded ) ? $decoded : [];
				} else {
					$value = [];
				}
			} elseif ( in_array( $key, $text_props, true ) ) {
				$value = is_scalar( $raw_value ) ? wp_kses_post( (string) $raw_value ) : '';
			} else {
				continue;
			}

			$displayed_gallery->$key = $value;
		}

		$response['items'] = $displayed_gallery->get_entities( false, false, false, 'both' );

		foreach ( $response['items'] as &$entity ) {
			$image = $entity;
   // phpcs:ignore WordPress.PHP.StrictInArray.MissingTrueStrict
			if ( in_array( $displayed_gallery->source, [ 'album','albums' ] ) ) {
				// Set the alttext of the preview image to the name of the gallery or album
				$image = $image_mapper->find( $entity->previewpic );
				if ( $image ) {
					if ( $entity->is_album ) {
						/* translators: %s: album name */
						$image->alttext = sprintf( \__( 'Album: %s', 'nggallery' ), $entity->name );
					} else {
						/* translators: %s: gallery title */
						$image->alttext = sprintf( \__( 'Gallery: %s', 'nggallery' ), $entity->title );
					}
				}

				// Prefix the id of an album with 'a'
				if ( $entity->is_album ) {
					$id                          = $entity->{$entity->id_field};
					$entity->{$entity->id_field} = 'a' . $id;
				}
			}

			// Get the thumbnail
			$entity->thumb_url  = $storage->get_image_url( $image, 'thumb', true );
			$entity->thumb_html = $storage->get_image_html( $image, 'thumb' );
		}

		return new \WP_REST_Response( $response );
	}
}
