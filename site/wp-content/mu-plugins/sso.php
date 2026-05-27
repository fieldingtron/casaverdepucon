<?php
/**
Plugin Name: SSO
Author: Garth Mortensen, Mike Hansen
Version: 0.2
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html
*/

function sso_check() {
    if ( ! isset( $_GET['salt'] ) || ! isset( $_GET['nonce'] ) || ! isset( $_GET['user'] ) ) {
        sso_req_login();
    }
    if ( sso_check_blocked() ) {
        sso_req_login();
    }

    $nonce  = sanitize_text_field( $_GET['nonce'] );
    $salt   = sanitize_text_field( $_GET['salt'] );
    $user   = sanitize_text_field( $_GET['user'] );
    $bounce = sanitize_text_field( isset( $_GET['bounce'] ) ? $_GET['bounce'] : '' );

    $hash   = substr( base64_encode( hash( 'sha256', $nonce . $salt, false ) ), 0, 64 );
    $stored = get_transient( 'sso_token' );

    if ( $stored !== false && hash_equals( (string) $stored, $hash ) ) {
        $wp_user = is_email( $user )
            ? get_user_by( 'email', $user )
            : get_user_by( 'id', (int) $user );

        if ( is_a( $wp_user, 'WP_User' ) ) {
            wp_set_current_user( $wp_user->ID, $wp_user->user_login );
            wp_set_auth_cookie( $wp_user->ID );
            do_action( 'wp_login', $wp_user->user_login, $wp_user );
            delete_transient( 'sso_token' );
            wp_safe_redirect( admin_url( $bounce ) );
            die();
        }
    }

    sso_add_failed_attempt();
    sso_req_login();
    die();
}
add_action( 'wp_ajax_nopriv_sso-check', 'sso_check' );
add_action( 'wp_ajax_sso-check', 'sso_check' );

function sso_req_login() {
    wp_safe_redirect( wp_login_url() );
    die();
}

function sso_get_attempt_key() {
    $ip = filter_var( $_SERVER['REMOTE_ADDR'], FILTER_VALIDATE_IP );
    return 'sso_rate_' . md5( $ip ?: 'unknown' );
}

function sso_add_failed_attempt() {
    $key      = sso_get_attempt_key();
    $attempts = (int) get_transient( $key );
    set_transient( $key, $attempts + 1, 300 );
}

function sso_check_blocked() {
    return ( (int) get_transient( sso_get_attempt_key() ) ) >= 5;
}
