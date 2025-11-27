FROM debian:bookworm
# O bookworm corresponde a versão 12 do Debian

RUN apt-get update && apt-get install -y mariadb-server \
    && rm -rf /var/lib/apt/lists/*

COPY tools/mariadb-init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb-init.sh

COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/

EXPOSE 3306

# cria diretórios e muda dono
RUN mkdir -p /var/lib/mysql /run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /run/mysqld
    

ENTRYPOINT ["/usr/local/bin/mariadb-init.sh"]
CMD ["mysqld"]
