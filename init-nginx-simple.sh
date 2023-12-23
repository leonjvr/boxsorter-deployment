#!/bin/sh

# Use the simplified NGINX configuration
cp /etc/nginx/conf.d/simple_nginx.conf /etc/nginx/conf.d/default.conf

# Start NGINX in the background
nginx &

# Keep the script running
while true; do sleep 60; done
