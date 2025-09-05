# Image
FROM mariadb:10

RUN chown -R mysql:mysql /var/lib/mysql/

EXPOSE 3306

# HEALTHCHECK --retries=3 --timeout=5s \
#     CMD ["sh", "-c", "mysqladmin ping -p$MARIADB_ROOT_PASSWORD | grep 'mysqld is alive' || exit 1"]

CMD ["mysqld"]
