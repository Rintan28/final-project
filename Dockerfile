# Multi-stage build for optimized production image
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files (if you have any)
# COPY package*.json ./
# RUN npm ci --only=production

# Copy source files
COPY index.html ./
COPY assets/ ./assets/ 2>/dev/null || true
COPY static/ ./static/ 2>/dev/null || true

# Minify HTML (optional)
RUN apk add --no-cache curl && \
    curl -o html-minifier.js https://cdn.jsdelivr.net/npm/html-minifier@4.0.0/dist/htmlminifier.min.js 2>/dev/null || true

# Production stage
FROM nginx:1.25-alpine

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache \
    curl \
    tzdata && \
    rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx-user -g nginx-user nginx-user

# Remove default nginx config and content
RUN rm -rf /etc/nginx/nginx.conf /usr/share/nginx/html/*

# Copy optimized nginx configuration
COPY --chown=nginx-user:nginx-user nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx-user:nginx-user default.conf /etc/nginx/conf.d/default.conf

# Copy application files
COPY --from=builder --chown=nginx-user:nginx-user /app/ /usr/share/nginx/html/

# Create necessary directories with proper permissions
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp && \
    chown -R nginx-user:nginx-user /var/cache/nginx /var/log/nginx /etc/nginx && \
    chmod -R 755 /var/cache/nginx && \
    chmod -R 644 /etc/nginx/conf.d/* && \
    chmod 644 /etc/nginx/nginx.conf

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Create health check endpoint
RUN echo '<!DOCTYPE html><html><head><title>Health Check</title></head><body><h1>OK</h1><p>Service is healthy</p></body></html>' > /usr/share/nginx/html/health

# Security: Remove unnecessary packages and files
RUN apk del curl && \
    rm -rf /tmp/* /var/tmp/* && \
    find /usr/share/nginx/html -name "*.map" -delete 2>/dev/null || true

# Use non-root user
USER nginx-user

# Expose port
EXPOSE 80

# Add labels for better container management
LABEL maintainer="DevOps Team <devops@company.com>" \
      version="1.0" \
      description="Modern Landing Page for DevOps Solutions" \
      org.opencontainers.image.title="DevOps Landing Page" \
      org.opencontainers.image.description="High-performance static landing page" \
      org.opencontainers.image.vendor="Your Company" \
      org.opencontainers.image.version="1.0.0"

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
