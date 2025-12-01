.PHONY: help up down build logs restart shell ps clean clean-all clean-volumes
.PHONY: dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps
.PHONY: prod-up prod-down prod-build prod-logs prod-restart prod-shell prod-ps
.PHONY: backend-shell gateway-shell mongo-shell backend-build backend-install backend-type-check backend-dev
.PHONY: db-reset db-backup status health

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE_DEV = docker compose -f docker/compose.development.yaml --env-file .env
COMPOSE_PROD = docker compose -f docker/compose.production.yaml --env-file .env
MODE ?= dev
SERVICE ?= backend
ARGS ?=

# Determine which compose command to use based on MODE
ifeq ($(MODE),prod)
	COMPOSE = $(COMPOSE_PROD)
else
	COMPOSE = $(COMPOSE_DEV)
endif

##@ Help

help: ## Display this help message
	@echo "Usage: make [target] [MODE=dev|prod] [SERVICE=service_name] [ARGS=additional_args]"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Docker Services

up: ## Start services (use: make up MODE=prod ARGS="--build")
	$(COMPOSE) up $(ARGS)

down: ## Stop services (use: make down MODE=prod ARGS="-v")
	$(COMPOSE) down $(ARGS)

build: ## Build containers (use: make build MODE=prod)
	$(COMPOSE) build $(ARGS)

logs: ## View logs (use: make logs SERVICE=backend MODE=prod)
	$(COMPOSE) logs -f $(SERVICE) $(ARGS)

restart: ## Restart services (use: make restart MODE=prod)
	$(COMPOSE) restart $(ARGS)

shell: ## Open shell in container (use: make shell SERVICE=gateway MODE=prod)
	$(COMPOSE) exec $(SERVICE) sh

ps: ## Show running containers (use: make ps MODE=prod)
	$(COMPOSE) ps

##@ Development Aliases

dev-up: ## Start development environment
	$(COMPOSE_DEV) up -d

dev-down: ## Stop development environment
	$(COMPOSE_DEV) down

dev-build: ## Build development containers
	$(COMPOSE_DEV) build

dev-logs: ## View development logs
	$(COMPOSE_DEV) logs -f

dev-restart: ## Restart development services
	$(COMPOSE_DEV) restart

dev-shell: ## Open shell in backend container (dev)
	$(COMPOSE_DEV) exec backend sh

dev-ps: ## Show running development containers
	$(COMPOSE_DEV) ps

backend-shell: ## Open shell in backend container (dev)
	$(COMPOSE_DEV) exec backend sh

gateway-shell: ## Open shell in gateway container (dev)
	$(COMPOSE_DEV) exec gateway sh

mongo-shell: ## Open MongoDB shell (dev)
	$(COMPOSE_DEV) exec mongodb mongosh -u admin -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2)

##@ Production Aliases

prod-up: ## Start production environment
	$(COMPOSE_PROD) up -d

prod-down: ## Stop production environment
	$(COMPOSE_PROD) down

prod-build: ## Build production containers
	$(COMPOSE_PROD) build

prod-logs: ## View production logs
	$(COMPOSE_PROD) logs -f

prod-restart: ## Restart production services
	$(COMPOSE_PROD) restart

prod-shell: ## Open shell in backend container (prod)
	$(COMPOSE_PROD) exec backend sh

prod-ps: ## Show running production containers
	$(COMPOSE_PROD) ps

##@ Backend Commands

backend-build: ## Build backend TypeScript (local)
	cd backend && npm run build

backend-install: ## Install backend dependencies (local)
	cd backend && npm install

backend-type-check: ## Type check backend code (local)
	cd backend && npm run type-check

backend-dev: ## Run backend in development mode (local, not Docker)
	cd backend && npm run dev

##@ Database Commands

db-reset: ## Reset MongoDB database (WARNING: deletes all data)
	@echo "WARNING: This will delete all data in the database!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_DEV) exec mongodb mongosh -u admin -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --eval "use ecommerce; db.dropDatabase()"; \
		echo "Database reset complete."; \
	else \
		echo "Database reset cancelled."; \
	fi

db-backup: ## Backup MongoDB database
	@mkdir -p backups
	@echo "Creating backup..."
	$(COMPOSE_DEV) exec -T mongodb mongodump --username=admin --password=$(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --authenticationDatabase=admin --db=ecommerce --archive > backups/mongodb-backup-$(shell date +%Y%m%d-%H%M%S).archive
	@echo "Backup created in backups/ directory"

##@ Cleanup Commands

clean: ## Remove containers and networks (both dev and prod)
	$(COMPOSE_DEV) down
	$(COMPOSE_PROD) down
	@echo "Containers and networks removed."

clean-all: ## Remove containers, networks, volumes, and images
	$(COMPOSE_DEV) down -v --rmi all
	$(COMPOSE_PROD) down -v --rmi all
	@echo "All containers, networks, volumes, and images removed."

clean-volumes: ## Remove all volumes (WARNING: deletes all data)
	@echo "WARNING: This will delete all persistent data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_DEV) down -v; \
		$(COMPOSE_PROD) down -v; \
		echo "All volumes removed."; \
	else \
		echo "Volume removal cancelled."; \
	fi

##@ Utilities

status: ps ## Alias for ps

health: ## Check service health
	@echo "=== Development Services ==="
	@$(COMPOSE_DEV) ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" 2>/dev/null || echo "Development services not running"
	@echo ""
	@echo "=== Production Services ==="
	@$(COMPOSE_PROD) ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" 2>/dev/null || echo "Production services not running"
