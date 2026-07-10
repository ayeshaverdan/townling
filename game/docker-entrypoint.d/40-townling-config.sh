#!/bin/sh
# Generate the runtime client config from the environment at container start.
# The Godot web client fetches /config.json before calling the API, so the
# backend URL is deploy-time configuration — no rebuild needed to repoint it.
#
# nginx's official image runs every executable script in /docker-entrypoint.d/
# before starting the server, which is the supported extension point.
set -eu

: "${TOWNLING_API_BASE:=http://localhost:8000}"

cat > /usr/share/nginx/html/config.json <<EOF
{
  "api_base": "${TOWNLING_API_BASE}"
}
EOF

echo "townling: wrote /config.json with api_base=${TOWNLING_API_BASE}"
