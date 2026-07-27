#!/bin/sh
set -e

# Gera config.json a partir da variável de ambiente,
# permitindo que o Flutter web leia a URL da API em runtime.
API_BASE_URL=${API_BASE_URL:-http://localhost:8080/api}

cat <<EOF > /usr/share/nginx/html/config.json
{"apiBaseUrl": "$API_BASE_URL"}
EOF

exec nginx -g 'daemon off;'
