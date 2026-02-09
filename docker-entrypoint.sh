#!/bin/sh
set -e

# Inject environment variables into the static HTML at startup
# SECRET_MESSAGE comes from the Kubernetes secret (sourced from Azure Key Vault via External Secrets)
SECRET="${SECRET_MESSAGE:-Secret not configured}"

# Replace the placeholder in index.html with the actual secret value
sed -i "s|{{SECRET_MESSAGE}}|${SECRET}|g" /usr/share/nginx/html/index.html

echo "✅ Secret injected into app"

# Start nginx
exec nginx -g 'daemon off;'
