#!/bin/sh
# Installs a local test site with WP-CLI. Safe to run any number of times:
# an already installed site is left untouched.
#
# Expects: SITE_URL, SITE_TITLE, WP_ADMIN_USER, WP_ADMIN_PASSWORD, WP_ADMIN_EMAIL
# plus the WORDPRESS_DB_* variables read by wp-config.php.
set -eu

cd /var/www/html

if wp core is-installed 2>/dev/null; then
    echo "${SITE_TITLE}: already installed ($(wp core version)), nothing to do."
    exit 0
fi

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

echo "${SITE_TITLE}: ready, WordPress $(wp core version), PHP $(php -r 'echo PHP_VERSION;')"
