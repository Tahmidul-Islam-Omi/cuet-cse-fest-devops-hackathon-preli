# Setup and Usage Guide

This guide provides detailed instructions for setting up and running the containerized e-commerce microservices application.

## Prerequisites

- Docker and Docker Compose installed
- Make (for Linux/Mac/WSL) or use Docker Compose commands directly
- Git

## Quick Start

### 1. Environment Configuration

Create a `.env` file in the root directory:

```env
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=SecureP@ssw0rd123!
MONGO_URI=mongodb://admin:SecureP%40ssw0rd123%21@mongodb:27017/ecommerce?authSource=admin
MONGO_DATABASE=ecommerce
BACKEND_PORT=3847
GATEWAY_PORT=5921
NODE_ENV=development
```

**Important:** Special characters in passwords must be URL-encoded in `MONGO_URI`:
- `@` → `%40`
- `!` → `%21`
- `#` → `%23`
- `$` → `%24`
- `%` → `%25`

### 2. Start Development Environment

**Using Makefile (Linux/Mac/WSL):**
```bash
make dev-up
```

**Using Docker Compose directly:**
```bash
docker compose -f docker/compose.development.yaml --env-file .env up -d
```

### 3. Verify Services

Check that all services are healthy:
```bash
make health
# or
docker compose -f docker/compose.development.yaml --env-file .env ps
```

### 4. Test the API

```bash
# Health checks
curl http://localhost:5921/health
curl http://localhost:5921/api/health

# Create a product
curl -X POST http://localhost:5921/api/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Product","price":99.99}'

# Get all products
curl http://localhost:5921/api/products
```

## Makefile Commands

The project includes a comprehensive Makefile for easy service management.

### View All Commands
```bash
make help
```

### Development Environment

```bash
make dev-up          # Start development environment (detached)
make dev-down        # Stop development environment
make dev-build       # Rebuild development containers
make dev-logs        # View development logs (follow mode)
make dev-restart     # Restart development services
make dev-ps          # Show running development containers
```

### Production Environment

```bash
make prod-up         # Start production environment (detached)
make prod-down       # Stop production environment
make prod-build      # Rebuild production containers
make prod-logs       # View production logs (follow mode)
make prod-restart    # Restart production services
make prod-ps         # Show running production containers
```

### Container Shell Access

```bash
make backend-shell   # Open shell in backend container
make gateway-shell   # Open shell in gateway container
make mongo-shell     # Open MongoDB shell
```

### Database Operations

```bash
make db-backup       # Backup MongoDB database to backups/ directory
make db-reset        # Reset database (WARNING: deletes all data)
```

### Cleanup

```bash
make clean           # Remove containers and networks (both dev and prod)
make clean-all       # Remove containers, networks, volumes, and images
make clean-volumes   # Remove all volumes (WARNING: deletes all data)
```

### Utilities

```bash
make health          # Check health status of all services
make status          # Show container status (alias for ps)
```

### Advanced Usage

```bash
# Start production with rebuild
make up MODE=prod ARGS="--build"

# View specific service logs in production
make logs SERVICE=backend MODE=prod

# Open shell in gateway container (production)
make shell SERVICE=gateway MODE=prod

# Restart with custom arguments
make restart MODE=dev ARGS="backend gateway"
```

## Docker Compose Commands (Without Makefile)

If you're on Windows PowerShell or don't have Make installed:

### Development

```powershell
# Start
docker compose -f docker/compose.development.yaml --env-file .env up -d

# View logs
docker compose -f docker/compose.development.yaml --env-file .env logs -f

# Stop
docker compose -f docker/compose.development.yaml --env-file .env down

# Rebuild
docker compose -f docker/compose.development.yaml --env-file .env up --build -d
```

### Production

```powershell
# Start
docker compose -f docker/compose.production.yaml --env-file .env up -d

# View logs
docker compose -f docker/compose.production.yaml --env-file .env logs -f

# Stop
docker compose -f docker/compose.production.yaml --env-file .env down
```

## Architecture Overview

### Services

1. **Gateway** (Port 5921 - Exposed)
   - API Gateway that routes requests to backend
   - Only service accessible from outside
   - Handles request forwarding and error handling

2. **Backend** (Port 3847 - Internal Only)
   - Product management service
   - TypeScript/Express application
   - Connects to MongoDB

3. **MongoDB** (Port 27017 - Internal Only)
   - Database for persistent storage
   - Data persists across container restarts

### Network Security

- Only gateway port (5921) is exposed to the host
- Backend and MongoDB are on internal Docker network only
- Services communicate via Docker DNS (service names)

## Implementation Features

### Docker Optimization
- **Multi-stage builds** for production (smaller images)
- **Alpine-based images** (~40MB vs ~900MB)
- **Layer caching** optimization for faster rebuilds
- **`.dockerignore`** files to reduce build context

### Security
- **Non-root user** execution in all containers
- **Read-only root filesystem** in production
- **Network isolation** (only gateway exposed)
- **Environment variable** management
- **URL-encoded credentials** for MongoDB

### High Availability
- **Health checks** on all services
- **Automatic restart** policies
- **Resource limits** in production (CPU/Memory)
- **Service dependency** management

### Development Experience
- **Hot-reload** for backend (tsx watch) and gateway (nodemon)
- **Separate dev/prod** configurations
- **Volume mounts** for live code updates
- **Comprehensive Makefile** commands

### Data Persistence
- **Named volumes** for MongoDB data
- **Separate dev/prod** volumes
- **Data survives** container restarts and rebuilds

## Troubleshooting

### Services won't start
```bash
# Check logs
make dev-logs

# Check if ports are already in use
docker ps
netstat -an | grep 5921
```

### MongoDB connection errors
- Ensure password is URL-encoded in `MONGO_URI`
- Check MongoDB container is healthy: `make health`
- Verify environment variables are loaded: `docker compose config`

### Permission errors
- Ensure Docker daemon is running
- On Linux, you may need to add your user to docker group: `sudo usermod -aG docker $USER`

### Clean slate
```bash
# Remove everything and start fresh
make clean-all
make dev-up
```

## Best Practices

1. **Always use `.env` file** - Never hardcode credentials
2. **Test in development first** - Use `make dev-up` before production
3. **Check health status** - Use `make health` to verify services
4. **Backup database** - Use `make db-backup` before major changes
5. **Clean up regularly** - Use `make clean` to remove unused containers
6. **Monitor logs** - Use `make dev-logs` or `make prod-logs` to watch for errors

## Production Deployment

For production deployment:

1. Update `.env` with production credentials
2. Set `NODE_ENV=production`
3. Start production environment: `make prod-up`
4. Verify health: `make health`
5. Test all endpoints
6. Monitor logs: `make prod-logs`

## Support

For issues or questions:
- Check logs: `make dev-logs` or `make prod-logs`
- Verify health: `make health`
- Review Docker Compose configuration in `docker/` directory
- Check Dockerfile configurations in `backend/` and `gateway/`
