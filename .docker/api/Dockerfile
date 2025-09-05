# Base stage
FROM dunglas/frankenphp:builder-php8.4-bookworm AS builder

# Set Caddy server name to "http://" to serve on 80 and not 443
# Read more: https://frankenphp.dev/docs/config/#environment-variables
ENV SERVER_NAME="http://"

# Retrieve APT lists
RUN apt-get update \
    # Install APT packages
    && apt-get install -y  \
    # Install GD requirements
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev libmagickwand-dev \
    # Install ZIP library
    libzip-dev \
    # Install ZIP binary
    zip \
    # Install Git binary
    git \
    # Install PostgresSQL library
    libpq-dev \
    # Install Process monitoring package
    procps \
    # Install Browsershot dependencies
    gconf-service libasound2 libatk1.0-0 libc6 \
    libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 \
    libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 \
    libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
    libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
    libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
    ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release \
    xdg-utils wget libgbm-dev libxshmfence-dev libxslt-dev \
    # Remove APT lists
    && rm -rf /var/lib/apt/lists/*



# Install PHP extensions using PECL
RUN pecl install \
    # Install Redis extension
    redis \
    # Compile PHP extensions
    && docker-php-ext-install \
    # Compile Zip extension
    zip \
    # Compile PDO extension
    pdo \
    # Compile Bcmath extension
    bcmath  \
    # Compile Exif extension
    exif  \
    # Compile XML extension
    xml  \
    # Compile XSL extension
    xsl  \
    # Compile Intl extension
    intl \
    # Compile MySQL extension
    pdo_mysql \
    # Compile Process Control extension
    pcntl \
    # Compile Opcache extension
    opcache \
    # Configure extensions
    && docker-php-ext-configure \
    # Configure GD extension
    gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ \
    # Install PHP extensions
    && docker-php-ext-install \
    # Install GD extension
    gd \
    # Enable PHP extensions
    && docker-php-ext-enable \
    # Enable Redis extension
    redis \
    # Enable Process Control extension
    pcntl

# Install Imagick
RUN git clone https://github.com/Imagick/imagick.git --depth 1 /tmp/imagick \
    && cd /tmp/imagick \
    && git fetch origin master \
    && git switch master \
    && cd /tmp/imagick \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable imagick

# Install Composer binary
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy PHP configuration file
COPY .docker/api/php.ini $PHP_INI_DIR/php.ini

# Copy OPcache configuration file
COPY .docker/api/conf.d/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini

# Configure OPcache environment variables
ENV OPCACHE_ENABLE=disable
ENV OPCACHE_ENABLE_CLI=0
ENV OPCACHE_JIT=tracing

# Specify working directory
WORKDIR /app

# Dev stage
FROM builder AS base-dev

# Install Xdebug extension
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Copy Xdebug configuration file
COPY .docker/api/conf.d/xdebug.ini ${PHP_INI_DIR}/conf.d/xdebug.ini

# Install Node.js
COPY --from=node:22-slim /usr/lib /usr/lib
COPY --from=node:22-slim /usr/local/share /usr/local/share
COPY --from=node:22-slim /usr/local/lib /usr/local/lib
COPY --from=node:22-slim /usr/local/include /usr/local/include
COPY --from=node:22-slim /usr/local/bin /usr/local/bin
COPY --from=node:22-slim /opt /opt

# Install Chokidar module
RUN npm install -g chokidar

# Install puppeteer
RUN npm install -g --unsafe-perm puppeteer

# Configure node_mobules path
ENV NODE_PATH=/usr/local/lib/node_modules

# Build stage
FROM builder AS build

# Specify environment variable for .env file
ENV APP_ENV=production

# Configure OPcache environment variables
ENV OPCACHE_ENABLE=1
ENV OPCACHE_ENABLE_CLI=1
ENV OPCACHE_JIT=tracing

# Copy application files
COPY --chown=www-data:www-data . .

# Specify filesystem permissions
RUN chmod -R 775 bootstrap/cache storage

# Install Composer dependencies
RUN composer install \
    --no-interaction \
    --no-dev \
    --optimize-autoloader

# # Optimize config loading
# RUN php artisan config:cache \
#     # Optimize route loading
#     && php artisan route:cache \
#     # Optimize view loading
#     && php artisan view:cache \
#     # Optimize event loading
#     && php artisan event:cache
