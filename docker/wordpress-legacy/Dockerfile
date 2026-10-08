# Legacy WordPress test site: simulates a neglected client host.
#
# Base: the last official WordPress image built for PHP 7.4 (PHP 7.4.33,
# WordPress 6.1.1, Debian 11, built November 2022). It is unmaintained on
# purpose: this site exists to prove the connector runs on old stacks.
# It is a local test fixture only, bound to 127.0.0.1, never deployed.
FROM wordpress:6.1.1-php7.4-apache

# Many cheap hosts run PHP without the sodium extension. Disabling it here
# forces WordPress to fall back on its bundled sodium_compat polyfill, so the
# connector's Ed25519 code is exercised on that path (see ADR-003).
RUN rm /usr/local/etc/php/conf.d/docker-php-ext-sodium.ini \
    && ! php -m | grep -qi '^sodium$'

COPY php.ini /usr/local/etc/php/conf.d/zz-morning-routine.ini
