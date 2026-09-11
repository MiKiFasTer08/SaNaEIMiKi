FROM alpine:3.19

RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    socat \
    tzdata \
    sqlite \
    nginx \
    gettext \
    fail2ban \
    && ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime

RUN curl -L https://github.com/mhsanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz -o /tmp/x-ui.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /usr/local/ \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui

RUN mkdir -p /etc/x-ui /var/log/x-ui

COPY nginx.conf.template /etc/nginx/nginx.conf.template
RUN sed -i 's/\r$//' /etc/nginx/nginx.conf.template

RUN cat > /start.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

echo "Starting X-UI + nginx reverse proxy..."

export NGINX_PORT=3000

echo "Starting fail2ban..."
mkdir -p /var/run/fail2ban
fail2ban-server -b || true

cd /usr/local/x-ui

echo "Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "Building nginx.conf for fixed port: $NGINX_PORT"
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 3

echo "Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
SCRIPT_EOF

RUN chmod +x /start.sh && sed -i 's/\r$//' /start.sh

CMD ["bash", "-c", "sed -i 's/\\r$//' /start.sh && exec bash /start.sh"]
