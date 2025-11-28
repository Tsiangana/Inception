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

# Load common secrets if present
load_secret "MYSQL_PASSWORD.txt" "MYSQL_PASSWORD"
load_secret "MYSQL_ROOT_PASSWORD.txt" "MYSQL_ROOT_PASSWORD"
load_secret "WP_ADMIN_PASSWORD.txt" "WP_ADMIN_PASSWORD"
load_secret "WP_ADMIN_PASSWORD2.txt" "WP_ADMIN_PASSWORD2"
load_secret "MYSQL_USER.txt" "MYSQL_USER"
load_secret "MYSQL_DATABASE.txt" "MYSQL_DATABASE"

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
    
    # Criar segundo usuário (ROLE AUTHOR = usuário normal)
    echo "Criando usuário adicional..."
    wp user create "$WP_ADMIN_USER2" "$WP_ADMIN_EMAIL2" \
        --role=author \
        --user_pass="$WP_ADMIN_PASSWORD2" \
        --allow-root \
        --path="$WP_PATH"
    
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