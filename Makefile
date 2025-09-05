# Include file with .env variables if existsMake

-include .env

# Define default values for variables
COMPOSE_FILE ?= compose.local.yml
COMPOSE_PROFILES ?=

DUMP_NAME ?= dump

PEST_ARGS ?= --bail
DUSK_ARGS ?=

#-----------------------------------------------------------
# Docker
#-----------------------------------------------------------

# Init variables for development environment
env.dev:
	cp .env.dev .env

# Init variables for production environment
env.prod:
	cp .env.prod .env

# Build and start containers
bup: build.all up

# Start containers
up:
	docker compose -f ${COMPOSE_FILE} up

# Start container daemonized
up.d:
	docker compose -f ${COMPOSE_FILE} up -d

# Force recreate containers and start
up.recreate:
	docker compose -f ${COMPOSE_FILE} up --force-recreate

# Stop containers
down:
	docker compose -f ${COMPOSE_FILE} down --remove-orphans

# Build containers
build:
	docker compose -f ${COMPOSE_FILE} build

# Build containers without cache
build.fresh:
	docker compose -f ${COMPOSE_FILE} build --no-cache

# Show list of running containers
ps:
	docker compose -f ${COMPOSE_FILE} ps

# Restart containers
restart:
	docker compose -f ${COMPOSE_FILE} restart

# Reboot containers
reboot: down up

# View output logs from containers
logs:
	docker compose -f ${COMPOSE_FILE} logs --tail 500

# Follow output logs from containers
logs.f:
	docker compose -f ${COMPOSE_FILE} logs --tail 500 -f

#-----------------------------------------------------------
# Client Application
#-----------------------------------------------------------

# Enter the app container
bash.client:
	docker compose -f ${COMPOSE_FILE} exec client /bin/bash

# Restart the app container
restart.client:
	docker compose -f ${COMPOSE_FILE} restart client

# Alias to restart the app container
rc: restart.client

# Install client package(s)
ni:
	docker compose -f ${COMPOSE_FILE} exec client ni ${PACKAGE}

# Upgrade client packages
nu:
	docker compose -f ${COMPOSE_FILE} exec client nu

# Install client package(s) with dev dependencies
ni.d:
	docker compose -f ${COMPOSE_FILE} exec client ni ${PACKAGE} -D

# Uninstall client package(s)
nun:
	docker compose -f ${COMPOSE_FILE} exec client nun ${PACKAGE}

#-----------------------------------------------------------
# API Application
#-----------------------------------------------------------

# Enter the app container
bash:
	docker compose -f ${COMPOSE_FILE} exec api /bin/bash

# Restart the app container
restart.api:
	docker compose -f ${COMPOSE_FILE} restart api

# Alias to restart the app container
ra: restart.api

# Run the tinker service
a.tinker:
	docker compose -f ${COMPOSE_FILE} exec api php artisan tinker

# Clear the app cache
a.cache.clear:
	docker compose -f ${COMPOSE_FILE} exec api php artisan cache:clear

# Migrate the database
a.migrate:
	docker compose -f ${COMPOSE_FILE} exec api php artisan migrate

# Rollback the database
a.rollback:
	docker compose -f ${COMPOSE_FILE} exec api php artisan migrate:rollback

# Seed the database
a.seed:
	docker compose -f ${COMPOSE_FILE} exec api php artisan db:seed

# Fresh the database state
a.fresh:
	docker compose -f ${COMPOSE_FILE} exec api php artisan migrate:fresh

# Refresh the database
a.refresh: a.fresh a.seed

# List available database dumps
db.dump.list:
	cd .data/mariadb/dumps && ls -A1

# Dump database into an encrypted and gzipped file
db.dump:
	docker compose -f ${COMPOSE_FILE} exec mariadb mysqldump -uroot -p${DB_ROOT_PASSWORD} --all-databases | gzip | openssl  enc -aes-256-cbc -k ${DB_ROOT_PASSWORD} > .data/mariadb/dumps/${DUMP_NAME}.sql.gz.enc

# Restore database from a dump (default dump name is dump)
# Restore specific dump by setting DUMP_NAME variable (db.restore DUMP_NAME=local)
db.restore:
	docker compose -f ${COMPOSE_FILE} exec mariadb openssl enc -d -aes-256-cbc -k ${DB_ROOT_PASSWORD} -in /var/mariadb/dumps/${DUMP_NAME}.sql.gz.enc | gzip -d > .data/mariadb/dumps/${DUMP_NAME}.sql
	docker compose -f ${COMPOSE_FILE} exec -T mariadb mysql -uroot -p${DB_ROOT_PASSWORD} < .data/mariadb/dumps/${DUMP_NAME}.sql

# Restart the queue process
queue.restart:
	docker compose -f ${COMPOSE_FILE} exec queue php artisan queue:restart

# Install composer dependencies
composer.install:
	docker compose -f ${COMPOSE_FILE} exec api composer install

# Install composer dependencies from stopped containers
r.composer.install:
	docker compose -f ${COMPOSE_FILE} run --rm --no-deps api composer install

# Alias to install composer dependencies
ci: composer.install

# Update composer dependencies
composer.update:
	docker compose -f ${COMPOSE_FILE} exec api composer update

# Update composer dependencies from stopped containers
r.composer.update:
	docker compose -f ${COMPOSE_FILE} run --rm --no-deps api composer update

# Alias to update composer dependencies
cu: composer.update

# Show outdated composer dependencies
composer.outdated:
	docker compose -f ${COMPOSE_FILE} exec api composer outdated

# PHP composer autoload command
composer.autoload:
	docker compose -f ${COMPOSE_FILE} exec api composer dump-autoload

# Generate a symlink to the storage directory
storage.link:
	docker compose -f ${COMPOSE_FILE} exec api php artisan storage:link --relative

# Give permissions of the storage folder to the www-data
storage.perm:
	sudo chmod -R 755 storage
	sudo chown -R www-data:www-data storage

# Give permissions of the storage folder to the current user
storage.perm.me:
	sudo chmod -R 755 storage
	sudo chown -R "$(shell id -u):$(shell id -g)" storage

# Give files ownership to the current user
own.me:
	sudo chown -R "$(shell id -u):$(shell id -g)" .

# Reload the Octane workers
octane.reload:
	docker compose -f ${COMPOSE_FILE} exec api php artisan octane:reload

# Alias to reload the Octane workers
or: octane.reload

#-----------------------------------------------------------
# Testing (only for development environment)
#-----------------------------------------------------------

# Run phpunit tests (requires 'phpunit/phpunit' composer package)
test:
	docker compose -f ${COMPOSE_FILE} exec api ./vendor/bin/pest ${PEST_ARGS}

# Alias to run pest tests
t: test

# Run phpunit tests with the coverage mode (TODO: install PCOV or other lib)
coverage:
	docker compose -f ${COMPOSE_FILE} exec api ./vendor/bin/pest --coverage-html ./api/.coverage

# Run dusk tests (requires 'laravel/dusk' composer package)
dusk:
	docker compose -f ${COMPOSE_FILE} exec api php artisan dusk

# Generate code metrics (requires 'phpmetrics/phpmetrics' composer package)
metrics:
	docker compose -f ${COMPOSE_FILE} exec api ./vendor/bin/phpmetrics --report-html=./api/.metrics api

#-----------------------------------------------------------
# Redis
#-----------------------------------------------------------

# Enter the redis container
redis:
	docker compose -f ${COMPOSE_FILE} exec redis redis-cli

# Flush the redis state
redis.flush:
	docker compose -f ${COMPOSE_FILE} exec redis redis-cli FLUSHALL

#-----------------------------------------------------------
# Swarm
#-----------------------------------------------------------

# Deploy the stack
swarm.deploy:
	docker stack deploy --compose-file ${COMPOSE_FILE} api

# Remove/stop the stack
swarm.rm:
	docker stack rm api

# List of stack services
swarm.services:
	docker stack services api

# List the tasks in the stack
swarm.ps:
	docker stack ps api

# Init the Docker Swarm Leader node
swarm.init:
	docker swarm init

#-----------------------------------------------------------
# Danger zone
#-----------------------------------------------------------

# Prune stopped docker containers and dangling images
danger.prune:
	docker system prune

# Backup database
# db.backup:
# 	docker compose -f ${COMPOSE_FILE} exec mariadb sh -c 'rm -rf /var/mariadb/backup/*'
# 	docker compose -f ${COMPOSE_FILE} exec mariadb mariabackup \
# 		--target-dir=/var/mariadb/backup/ \
# 	       --user root --password ${DB_ROOT_PASSWORD} \
# 		--backup --stream=xbstream | gzip | openssl enc -aes-256-cbc -k ${DB_ROOT_PASSWORD} > .data/mariadb/backup/backup.xb.gz.enc

# Restore database
# db.restore:
	# docker compose -f ${COMPOSE_FILE} run --rm --no-deps mariadb sh -c 'openssl enc -d -aes-256-cbc -k secret -in /var/mariadb/backup/backup.xb.gz.enc |gzip -d| mbstream -x'
	# docker compose -f ${COMPOSE_FILE} run --rm --no-deps mariadb mariabackup --prepare --target-dir /var/mariadb/backup
	# docker compose -f ${COMPOSE_FILE} run --rm --no-deps mariadb sh -c 'rm -rf /var/lib/mysql/*'
	# docker compose -f ${COMPOSE_FILE} run --rm --no-deps mariadb mariabackup --copy-back --target-dir /var/mariadb/backup
	# docker compose -f ${COMPOSE_FILE} run --rm --no-deps mariadb chown -R mysql:mysql /var/lib/mysql/
