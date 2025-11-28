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

# Common secrets
load_secret "MYSQL_PASSWORD.txt" "MYSQL_PASSWORD"
load_secret "MYSQL_ROOT_PASSWORD.txt" "MYSQL_ROOT_PASSWORD"
load_secret "MYSQL_DATABASE.txt" "MYSQL_DATABASE"
load_secret "MYSQL_USER.txt" "MYSQL_USER"

DATA_DIR="/var/lib/mysql"
INIT_MARKER="$DATA_DIR/.inception_initialized"
SOCKET="/run/mysqld/mysqld.sock"

echo "Garantindo permissões corretas..."
chown -R mysql:mysql "$DATA_DIR"

if [ ! -f "$INIT_MARKER" ]; then
    echo "Inicializando banco de dados..."

    if [ ! -d "$DATA_DIR/mysql" ]; then
        echo "Criando arquivos do banco de dados..."
        mariadb-install-db --user=mysql --ldata="$DATA_DIR"
    fi

    echo "Iniciando MariaDB temporário..."
    mysqld --user=mysql --skip-networking --socket="$SOCKET" &
    TEMP_PID=$!

    echo "Aguardando MariaDB iniciar..."
    for i in {1..60}; do
        if mysqladmin --socket="$SOCKET" ping >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    echo "Configurando users..."
    mysql --socket="$SOCKET" -u root <<EOSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

    echo "Encerrando MariaDB temporário..."
    mysqladmin --socket="$SOCKET" -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown || true
    wait $TEMP_PID || true

    touch "$INIT_MARKER"
    echo "Inicialização concluída!"
fi

echo "Iniciando MariaDB..."
exec mysqld --user=mysql
