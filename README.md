#PHP5.4.3 DOCKERFILE (fpm with xdebug)
This is docker image for local development for project that runs on php 5.4.3

    docker container run --rm --name php-fpm e XDEBUG_CONFIG="remote_host=YOUR_HOST_IP remote_port=REMOTE_PORT" -p 9900:9000 -v SOME_PATH_TO_MOUNT_IF_NEEDED php:5.4-fpm-xdebug