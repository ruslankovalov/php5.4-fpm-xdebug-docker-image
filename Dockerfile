FROM ubuntu:14.04

#install all necessary libs for php compilation
RUN apt-get update \
    && apt-get install dialog apt-utils -y \
    && apt-get install build-essential -y \
    && apt-get install wget -y \
    && apt-get install libxml2-dev -y \
    && apt-get install libcurl4-openssl-dev pkg-config -y \
    && apt-get install libbz2-dev -y \
    && apt-get install libjpeg-turbo8-dev -y \
    && apt-get install libpng-dev -y \
    && apt-get install libfreetype6-dev -y \
    && mkdir /usr/include/freetype2/freetype \
    && ln -s /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h \
    && apt-get install libc-client-dev -y \
    && ln -s /usr/lib/x86_64-linux-gnu/libXpm.a /usr/lib/libXpm.a \
    && ln -s /usr/lib/x86_64-linux-gnu/libXpm.so /usr/lib/libXpm.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.a /usr/lib/liblber.a \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.a /usr/lib/libldap_r.a \
    && apt-get install libmcrypt-dev libreadline-dev -y \
    && apt-get install libpq-dev -y \
    && apt-get install libxslt-dev -y \
    && apt-get install curl -y \
    && apt-get update \
    && apt-get upgrade -y

#Download and compile php
RUN wget http://museum.php.net/php5/php-5.4.3.tar.bz2 \
    && tar -vxf php-5.4.3.tar.bz2
WORKDIR /php-5.4.3
RUN ./configure --prefix=/opt/php-5.4.3 --with-pdo-pgsql --with-zlib-dir --with-freetype-dir --enable-mbstring \
    --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-mcrypt --with-zlib --with-gd --with-pgsql \
    --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem \
    --enable-sysvshm --enable-pcntl --enable-mbregex --enable-exif --enable-bcmath --enable-zip --with-pcre-regex \
     -with-mysql --with-pdo-mysql --with-mysqli --with-jpeg-dir=/usr --with-png-dir=/usr --enable-gd-native-ttf \
     --with-openssl --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib --enable-ftp --with-imap \
      -with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-fpm --enable-xdebug

#This patch is applied not to have errors with libxml2. It throws errors after version 2.9.0 and this patch is applied
#not to have those errors. Feel free to comment out two lines below and experience those errors
COPY somepatchbeforemake somepatchbeforemake
RUN patch -p0 -i somepatchbeforemake

RUN make \
#    && make test \
    && make install

#create bin symlinks and congigure a bit
RUN ln -s /opt/php-5.4.3/bin/php /usr/bin/php \
    && ln -s /opt/php-5.4.3/sbin/php-fpm /usr/bin/php-fpm \
    && cp php.ini-development /opt/php-5.4.3/lib/php.ini \
    && cp /opt/php-5.4.3/etc/php-fpm.conf.default /opt/php-5.4.3/etc/php-fpm.conf \
    && echo '[global]' >> /opt/php-5.4.3/etc/php-fpm.conf \
    && echo 'daemonize = no' >> /opt/php-5.4.3/etc/php-fpm.conf \
    && echo 'error_log = /proc/self/fd/2' >> /opt/php-5.4.3/etc/php-fpm.conf \
    && echo '[www]' >> /opt/php-5.4.3/etc/php-fpm.conf \
    && echo 'access.log = /proc/self/fd/2' >> /opt/php-5.4.3/etc/php-fpm.conf \
    && sed -i "s/listen = 127.0.0.1:9000/listen = 9000/" /opt/php-5.4.3/etc/php-fpm.conf

WORKDIR /

#Download and compile xdebug

RUN wget https://github.com/xdebug/xdebug/archive/XDEBUG_2_4_1.zip \
    && sudo apt-get install unzip -y \
    && unzip XDEBUG_2_4_1.zip
WORKDIR xdebug-XDEBUG_2_4_1
RUN apt-get install autoconf -y \
    && /opt/php-5.4.3/bin/phpize \
    && ./configure --enable-xdebug --with-php-config=/opt/php-5.4.3/bin/php-config \
    && make
RUN mkdir /usr/lib/php \
    && mkdir /usr/lib/php/5.4 \
    && cp /xdebug-XDEBUG_2_4_1/modules/xdebug.so /usr/lib/php/5.4/xdebug.so

#Xdebug config
ARG XDEBUG_REMOTE_HOST="localhost"
ARG XDEBUG_REMOTE_PORT=9000
ARG XDEBUG_REMOTE_AUTOSTART="off"

RUN echo "[xdebug]" >> /opt/php-5.4.3/lib/php.ini \
    && echo "zend_extension=\"/usr/lib/php/5.4/xdebug.so\"" >> /opt/php-5.4.3/lib/php.ini \
    && echo "xdebug.idekey=\"php-storm\"" >> /opt/php-5.4.3/lib/php.ini \
    && echo "xdebug.remote_enable=on" >> /opt/php-5.4.3/lib/php.ini \
    && echo "xdebug.remote_host=$XDEBUG_REMOTE_HOST" >> /opt/php-5.4.3/lib/php.ini \
    && echo "xdebug.remote_port=$XDEBUG_REMOTE_PORT" >> /opt/php-5.4.3/lib/php.ini \
    && echo "xdebug.remote_autostart=$XDEBUG_REMOTE_AUTOSTART" >> /opt/php-5.4.3/lib/php.ini \
    && mkdir /var/log/xdebug \
    && touch /var/log/xdebug/remote_log.log \
    && chown www-data:www-data /var/log/xdebug/remote_log.log \
    && echo "xdebug.remote_log=/var/log/xdebug/remote_log.log" >> /opt/php-5.4.3/lib/php.ini

RUN mkdir /var/www
WORKDIR /var/www

#RUN touch endless.sh \
#    && echo "#/bin/bash" > endless.sh \
#    && echo "while true; do echo 1; sleep 2; done" >> endless.sh
#CMD ["/bin/bash","/endless.sh"]
CMD ["php-fpm"]
EXPOSE 9000
