FROM nginx:1.27-alpine

# Remove default nginx config and site
RUN rm -rf /etc/nginx/conf.d/default.conf /usr/share/nginx/html/*

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy application source
COPY src/ /usr/share/nginx/html/

# Copy entrypoint script (injects secrets at runtime)
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/healthz || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
