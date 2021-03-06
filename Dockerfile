FROM php:7.0-fpm
ENV HOME_DIR /var/www/html/
ENV WORK_DIR /var/www/html/

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends apt-utils zlib1g-dev \
    && apt-get install zlib1g-dev libxml2-dev -y libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql \
    && docker-php-ext-install mysqli soap \
    && docker-php-ext-install zip \
    && apt-get install -y supervisor nginx \
    && sed -i 's/^\(\[supervisord\]\)$/\1\nnodaemon=true/' /etc/supervisor/supervisord.conf \
    && apt-get install -qq -y --no-install-recommends curl gnupg git \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && curl -sL http://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -qq -y --no-install-recommends nodejs && rm -rf /var/lib/apt/lists/* \
    && npm install npm@latest -g

RUN useradd -m -d $HOME_DIR -s /bin/bash ojs

RUN touch /var/log/php-errors.log
RUN chown ojs /var/log/php-errors.log

RUN rm -Rf /var/www/html/
RUN chown ojs -R /var/www/html
RUN chown ojs -R /var/log/nginx
RUN chown ojs -R /var/lib/nginx
USER ojs
RUN git clone https://github.com/pkp/ojs.git $WORK_DIR
RUN mkdir /var/www/html/files
RUN chown ojs -R /var/www/html/files
WORKDIR $WORK_DIR
RUN git checkout ojs-stable-3_1_0
RUN git submodule update --init --recursive
COPY config/config.TEMPLATE.inc.php config.inc.php
RUN cd lib/pkp && composer update
RUN cd ../..
RUN cd plugins/paymethod/paypal && composer update
RUN cd ../../..
RUN cd plugins/generic/citationStyleLanguage && composer update
RUN cd ../../..
RUN npm install && npm run build
# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
