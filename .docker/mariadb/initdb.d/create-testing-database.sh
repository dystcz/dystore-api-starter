#!/usr/bin/env bash

mysql --user=root --password="$MARIADB_ROOT_PASSWORD" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS testing;
    GRANT ALL PRIVILEGES ON \`testing%\`.* TO '$MARIADB_USER'@'%';
EOSQL
