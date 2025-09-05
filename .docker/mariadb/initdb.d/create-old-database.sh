#!/usr/bin/env bash

mysql --user=root --password="$MARIADB_ROOT_PASSWORD" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS candykeys-old;
    GRANT ALL PRIVILEGES ON \`candykeys-old%\`.* TO '$MARIADB_USER'@'%';
EOSQL
