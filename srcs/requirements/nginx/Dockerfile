FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*

COPY tools/generate_ssl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_ssl.sh

COPY conf/default.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /var/www/html

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/generate_ssl.sh"]
CMD ["nginx", "-g", "daemon off;"]
