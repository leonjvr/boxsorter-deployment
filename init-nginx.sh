#!/bin/sh

# Start with the initial HTTP configuration
envsubst '${DOMAIN}' < /etc/nginx/conf.d/reverse_proxy.conf.template > /etc/nginx/conf.d/default.conf

# Start NGINX in the background
nginx &

# Wait a bit for Certbot to possibly obtain certificates
sleep 30

# Check if SSL certificates exist
if [ -e "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    # If SSL certificates exist, switch to the HTTPS configuration
    envsubst '${DOMAIN}' < /etc/nginx/conf.d/reverse_proxy_https.conf.template > /etc/nginx/conf.d/default.conf

    # Gracefully reload NGINX to apply the new configuration
    nginx -s reload
fi

# Keep the script running
while true; do sleep 60; done
