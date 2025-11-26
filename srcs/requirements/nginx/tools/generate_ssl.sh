#!/bin/bash
set -e

SSL_DIR="/etc/nginx/ssl"

mkdir -p $SSL_DIR

if [ ! -f "$SSL_DIR/nginx.crt" ] || [ ! -f "$SSL_DIR/nginx.key" ]; then
    echo "🔐 Gerando certificado SSL autoassinado..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/nginx.key" \
        -out "$SSL_DIR/nginx.crt" \
        -subj "/C=AO/ST=Luanda/L=Luanda/O=42School/OU=Inception/CN=localhost"
else
    echo "🔐 Certificado SSL já existe."
fi

echo "🚀 Iniciando NGINX..."
exec "$@"
