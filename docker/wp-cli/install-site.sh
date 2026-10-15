#!/bin/sh
# Prepares a local test site with WP-CLI. Safe to run any number of times:
# WordPress is installed only once, and every step after that is idempotent.
#
# Expects: SITE_URL, SITE_TITLE, WP_ADMIN_USER, WP_ADMIN_PASSWORD, WP_ADMIN_EMAIL
# plus the WORDPRESS_DB_* variables read by wp-config.php.
set -eu

cd /var/www/html

if wp core is-installed 2>/dev/null; then
    echo "${SITE_TITLE}: WordPress already installed ($(wp core version))."
else
    echo "${SITE_TITLE}: installing WordPress at ${SITE_URL}"
    wp core install \
        --url="${SITE_URL}" \
        --title="${SITE_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    # Pretty permalinks, like real client sites (REST API under /wp-json/).
    # The official WordPress image already ships the Apache .htaccess rules.
    wp rewrite structure '/%postname%/'
fi

# The connector is mounted from ./connector (see docker-compose.yml).
# Activating an already active plugin is a no-op.
wp plugin activate morning-routine

echo "${SITE_TITLE}: ready, WordPress $(wp core version), PHP $(php -r 'echo PHP_VERSION;'), connector $(wp plugin get morning-routine --field=status)"
