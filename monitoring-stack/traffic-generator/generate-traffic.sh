#!/bin/sh
# generate-traffic.sh
# Simulates random user traffic against pay-api so we can see real metrics.
# Runs inside a Docker container alongside the monitoring stack.

APP_URL="http://pay-api:5000"

echo "[traffic-generator] Starting traffic against $APP_URL ..."

while true; do
    # Hit the home page (more frequently)
    curl -s -o /dev/null "$APP_URL/"
    
    # Random short sleep (1-3 seconds)
    sleep $(( RANDOM % 3 + 1 ))

    # Hit the payment page (less frequently)
    if [ $(( RANDOM % 3 )) -eq 0 ]; then
        curl -s -o /dev/null "$APP_URL/payment"
    fi

    # Hit the health endpoint occasionally
    if [ $(( RANDOM % 5 )) -eq 0 ]; then
        curl -s -o /dev/null "$APP_URL/health"
    fi

    sleep $(( RANDOM % 2 + 1 ))
done
