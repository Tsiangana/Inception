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

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Copiar nosso script de inicializacao
COPY tools/wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

# Copiar configuracao do PHP-FPM
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# POPULAR O VOLUME
RUN mkdir -p /usr/src/wordpress && \
    cp -r /var/www/html/* /usr/src/wordpress/

# Rodar script init wordpress
COPY tools/init_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_wordpress.sh

EXPOSE 9000

CMD ["bash", "/usr/local/bin/wp-init.sh"]