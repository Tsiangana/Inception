#!/bin/bash
set -e

DATA_DIR="/var/lib/mysql"

if [ ! -d "$DATA_DIR/mysql" ]; then
    echo "Inicializando banco de dados..."
    mysql_install_db --user=mysql --ldata="$DATA_DIR"
    
    TEMP_SQL="/tmp/init.sql"
    
    # Criar banco de dados
    echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;" > $TEMP_SQL
    
    # Criar usuário com senha para localhost e %
    echo "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';" >> $TEMP_SQL
    echo "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';" >> $TEMP_SQL
    
    # Garantir que usa mysql_native_password (não unix_socket)
    echo "ALTER USER '${MYSQL_USER}'@'localhost' IDENTIFIED VIA mysql_native_password;" >> $TEMP_SQL
    echo "SET PASSWORD FOR '${MYSQL_USER}'@'localhost' = PASSWORD('${MYSQL_PASSWORD}');" >> $TEMP_SQL
    
    # Dar privilégios
    echo "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';" >> $TEMP_SQL
    echo "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';" >> $TEMP_SQL
    
    # Configurar root
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" >> $TEMP_SQL
    
    echo "FLUSH PRIVILEGES;" >> $TEMP_SQL
    
    echo "Aplicando configurações iniciais..."
    mysqld --user=mysql --bootstrap < $TEMP_SQL
    rm -f $TEMP_SQL
    
    echo "Inicialização completa!"
fi

echo "Iniciando MariaDB..."
exec mysqld --user=mysql