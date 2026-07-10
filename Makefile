# Townling — one-command developer workflow.
# Run `make` or `make help` to list targets.

COMPOSE := docker compose

.DEFAULT_GOAL := help
.PHONY: help setup up down stop build rebuild logs ps \
        migrate makemigrations superuser backend-shell shell test lint fmt \
        game-build game-logs open clean

help: ## Show this help
	@echo "Townling — available commands:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.env: ## Create .env from .env.example if missing
	@test -f .env || (cp .env.example .env && echo "Created .env from .env.example")

setup: .env ## First-time setup: create .env and sync backend deps locally (for editor/tests)
	@cd backend && uv sync --dev
	@echo "Setup complete. Run 'make up' to start the stack."

up: .env ## Build (if needed) and start the whole stack in the background
	$(COMPOSE) up --build -d
	@echo ""
	@echo "  Backend API : http://localhost:8000/api/"
	@echo "  Game (web)  : http://localhost:8080/"
	@echo ""

down: ## Stop and remove containers
	$(COMPOSE) down

stop: ## Stop containers without removing them
	$(COMPOSE) stop

build: .env ## Build all images
	$(COMPOSE) build

rebuild: .env ## Rebuild all images from scratch (no cache)
	$(COMPOSE) build --no-cache

logs: ## Tail logs from all services
	$(COMPOSE) logs -f

ps: ## Show running services
	$(COMPOSE) ps

# --- Backend ---------------------------------------------------------------

migrate: ## Apply Django migrations inside the backend container
	$(COMPOSE) run --rm backend python manage.py migrate

makemigrations: ## Generate Django migrations
	$(COMPOSE) run --rm backend python manage.py makemigrations

superuser: ## Create a Django admin superuser
	$(COMPOSE) run --rm -it backend python manage.py createsuperuser

backend-shell: ## Open a shell in the backend container
	$(COMPOSE) exec backend sh

shell: ## Open the Django shell
	$(COMPOSE) run --rm -it backend python manage.py shell

test: ## Run backend tests
	$(COMPOSE) run --rm backend pytest -q

lint: ## Lint the backend with ruff
	$(COMPOSE) run --rm backend ruff check .

fmt: ## Format the backend with ruff
	$(COMPOSE) run --rm backend ruff format .

# --- Game ------------------------------------------------------------------

game-build: .env ## Build only the game (Godot web export) image
	$(COMPOSE) build game

game-logs: ## Tail the game (nginx) logs
	$(COMPOSE) logs -f game

# --- Utility ---------------------------------------------------------------

open: ## Open both URLs in the default browser (macOS)
	@open http://localhost:8080/ http://localhost:8000/api/ 2>/dev/null || \
		echo "Open http://localhost:8080/ and http://localhost:8000/api/"

clean: ## Stop stack and remove images + local build artifacts
	$(COMPOSE) down --rmi local --volumes --remove-orphans
	@rm -rf game/build game/.godot backend/db.sqlite3
	@echo "Cleaned."
