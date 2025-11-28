#!/bin/bash
set -e

# If secrets are provided as files (mounted to /run/secrets), prefer them
SECRETS_DIR="/run/secrets"
load_secret() {
  local file="$SECRETS_DIR/$1"
  local varname="$2"
  if [ -z "${!varname}" ] && [ -f "$file" ]; then
    export "$varname"="$(cat "$file")"
  fi
}

load_secret "MYSQL_PASSWORD.txt" "MYSQL_PASSWORD"
load_secret "MYSQL_ROOT_PASSWORD.txt" "MYSQL_ROOT_PASSWORD"
load_secret "WP_ADMIN_PASSWORD.txt" "WP_ADMIN_PASSWORD"
load_secret "WP_ADMIN_PASSWORD2.txt" "WP_ADMIN_PASSWORD2"
load_secret "MYSQL_USER.txt" "MYSQL_USER"
load_secret "MYSQL_DATABASE.txt" "MYSQL_DATABASE"

/usr/local/bin/init_wordpress.sh

WP_PATH="/var/www/html"
INIT_MARKER="$WP_PATH/.wordpress_installed"

echo "🔧 Ajustando permissões..."
chown -R www-data:www-data $WP_PATH

# Configuração inicial
if [ ! -f "$INIT_MARKER" ]; then
    echo "🚀 Primeira inicialização do WordPress..."

    # Esperar o MariaDB responder
    echo "⏳ Aguardando MariaDB..."
    until mysql -h"$WORDPRESS_DB_HOST" -P"${WORDPRESS_DB_PORT:-3306}" \
      -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" >/dev/null 2>&1; do
        sleep 2
    done
    echo "🚀 Done Mariadb"

    echo "📦 Criando wp-config.php..."
    cp $WP_PATH/wp-config-sample.php $WP_PATH/wp-config.php

    sed -i "s/database_name_here/${MYSQL_DATABASE}/" $WP_PATH/wp-config.php
    sed -i "s/username_here/${MYSQL_USER}/" $WP_PATH/wp-config.php
    sed -i "s/password_here/${MYSQL_PASSWORD}/" $WP_PATH/wp-config.php
    sed -i "s/localhost/${WORDPRESS_DB_HOST}/" $WP_PATH/wp-config.php

    echo "💾 Finalizando WP..."
    chown -R www-data:www-data $WP_PATH

    touch "$INIT_MARKER"
    echo "✔️ WordPress instalado!"
fi

echo "🔥 Iniciando PHP-FPM..."
exec php-fpm8.2 -F
