#!/bin/sh

docker-compose stop nginx
docker-compose stop certbot

docker-compose rm -f nginx
docker-compose rm -f certbot

docker-compose -f docker-compose.yml --env-file .env up -d

docker-compose logs -f nginx

docker-compose logs -f certbot