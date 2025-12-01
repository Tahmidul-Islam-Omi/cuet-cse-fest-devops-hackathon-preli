# Production Dockerfile for Backend
# Multi-stage build for optimized image size

# Stage 1: Builder
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including devDependencies for build)
RUN npm install

# Copy source code and tsconfig
COPY . .

# Build TypeScript to JavaScript
RUN npm run build

# Remove devDependencies to reduce size
RUN npm prune --production

# Stage 2: Dependencies
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files and install production dependencies only
COPY package*.json ./
RUN npm install --only=production && \
    npm cache clean --force && \
    # Remove unnecessary files from node_modules to reduce size
    find /app/node_modules -type f -name "*.md" -delete && \
    find /app/node_modules -type f -name "*.ts" -delete && \
    find /app/node_modules -type f -name "LICENSE*" -delete && \
    find /app/node_modules -name "test" -type d -prune -exec rm -rf {} + && \
    find /app/node_modules -name "tests" -type d -prune -exec rm -rf {} + && \
    find /app/node_modules -name "__tests__" -type d -prune -exec rm -rf {} + && \
    find /app/node_modules -name "*.spec.js" -type f -delete && \
    find /app/node_modules -name "*.test.js" -type f -delete

# Stage 3: Production Runner (minimal)
FROM node:20-alpine AS runner

# Set NODE_ENV to production
ENV NODE_ENV=production

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    # Remove unnecessary packages to reduce size
    rm -rf /usr/share/man/* \
           /usr/share/doc/* \
           /tmp/* \
           /var/cache/apk/*

# Copy production dependencies from deps stage
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy built application from builder
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Switch to non-root user
USER nodejs

# Expose backend port
EXPOSE 3847

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3847/api/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start production server directly with node (no npm)
CMD ["node", "dist/index.js"]
