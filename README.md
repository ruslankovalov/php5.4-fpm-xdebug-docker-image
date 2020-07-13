##PHP5.4.3 DOCKERFILE (fpm with xdebug)

This is docker image for local development for project that runs on php 5.4.3

### Usage
####Build with 
    
    docker image build  ./ \
    --build-arg XDEBUG_REMOTE_HOST={{REMOTE_HOST}} \
    --build-arg XDEBUG_REMOTE_PORT={{REMOTE_PORT}} \
    --build-arg XDEBUG_REMOTE_AUTOSTART={{ON_OR_OFF}} \
    --tag php:5.4-fpm-xdebug
    
If build arguments are not supplied, default values of 'localhost', '9000' and 'off' will be used

####Run with

    docker container run --rm --name php-fpm \
    -p {{FREE_LOCAL_PORT_FOR_FASTCGI}}:9000 \
    -v {{SOME_PATH_TO_MOUNT_IF_NEEDED}} \
    php:5.4-fpm-xdebug