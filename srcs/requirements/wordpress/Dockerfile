FROM debian:12

RUN apt update -y && apt upgrade -y && \
    apt install -y php php-fpm php-mysqli php-curl php-gd php-xml php-mbstring \
                    php-cli php-zip php-json wget curl mariadb-client

# Criando diretorio do wordPress
RUN mkdir -p /var/www/html

# Baixando todos os pacotes WordPress
RUN wget https://wordpress.org/latest.tar.gz -P /tmp && \
    tar -xzf /tmp/latest.tar.gz -C /var/www/html --strip-components=1 && \
    rm -rf /tmp/latest.tar.gz

# Copiar nosso script de inicializacao
COPY tools/wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

# Copiar configuracao do PHP-FPM
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

EXPOSE 9000

CMD ["bash", "/usr/local/bin/wp-init.sh"]