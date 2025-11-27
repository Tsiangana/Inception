#!/bin/bash
set -e

WP_PATH="/var/www/html"

# Copiar arquivos do WordPress se o volume estiver vazio
if [ ! -f "$WP_PATH/index.php" ]; then
    echo "Copiando arquivos do WordPress..."
    cp -r /usr/src/wordpress/* "$WP_PATH/"
fi

# Aguardar MariaDB
echo "Aguardando MariaDB estar pronto..."
until mysql -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT 1" >/dev/null 2>&1; do
    echo "Aguardando MariaDB..."
    sleep 3
done
echo "MariaDB está pronto!"

# Configurar WordPress apenas na primeira vez
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "Configurando WordPress..."
    
    # Criar wp-config.php
    wp config create \
        --allow-root \
        --path="$WP_PATH" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb" \
        --skip-check
    
    # Instalar WordPress
    wp core install \
        --allow-root \
        --path="$WP_PATH" \
        --url="https://$DOMAIN_NAME" \
        --title="Inception Project" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL"
    
    echo "WordPress instalado com sucesso!"
    
    # Listar usuários criados
    echo "Usuários criados:"
    wp user list --allow-root --path="$WP_PATH"
fi

# Ajustar permissões
chown -R www-data:www-data "$WP_PATH"

# Iniciar PHP-FPM
echo "Iniciando PHP-FPM..."
mkdir -p /run/php
exec php-fpm8.2 -F