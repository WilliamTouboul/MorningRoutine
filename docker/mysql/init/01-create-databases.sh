#!/bin/bash
# Creates one database and one dedicated user per application.
# Run automatically by the MySQL image on first start only (empty data volume).
# To re-run it: `docker compose down -v` (deletes all local data), then `up` again.
set -euo pipefail

# Avoids passing the password on the command line (visible in `ps`).
export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"

create_app_database() {
    local db="$1" user="$2" password="$3"
    echo "Creating database '${db}' and user '${user}'"
    mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${db}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${user}'@'%' IDENTIFIED BY '${password}';
GRANT ALL PRIVILEGES ON \`${db}\`.* TO '${user}'@'%';
SQL
}

create_app_database "$WP_LEGACY_DB_NAME" "$WP_LEGACY_DB_USER" "$WP_LEGACY_DB_PASSWORD"
create_app_database "$WP_MODERN_DB_NAME" "$WP_MODERN_DB_USER" "$WP_MODERN_DB_PASSWORD"
create_app_database "$DASHBOARD_DB_NAME" "$DASHBOARD_DB_USER" "$DASHBOARD_DB_PASSWORD"

mysql --protocol=socket -uroot -e "FLUSH PRIVILEGES;"
