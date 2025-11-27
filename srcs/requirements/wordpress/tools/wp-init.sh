#!/bin/bash
set -e

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
