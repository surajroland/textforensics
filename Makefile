# TextForensics Development Makefile
# Supports multi-stage builds and professional deployment workflows

.PHONY: help install install-dev test lint format clean build dev shell train api
.PHONY: build-dev build-api build-train push pull logs down clean-all setup
.PHONY: clean-project clean-volumes shell-dev shell-train shell-api

# Default environment variables
DOCKER_REGISTRY ?= ghcr.io/$(shell git remote get-url origin | sed 's/.*github.com[:/]\([^/]*\).*/\1/' | tr '[:upper:]' '[:lower:]')
VERSION ?= latest
COMPOSE_FILE ?= docker-compose.yml
SERVICE_DEV = textforensics-dev
SERVICE_TRAIN = textforensics-train
SERVICE_API = textforensics-api

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)🚀 TextForensics Development Commands:$(NC)"
	@echo "$(GREEN)Local Development:$(NC)"
	@echo "  install       Install package locally"
	@echo "  install-dev   Install with development dependencies"
	@echo "  install-train Install with training dependencies"
	@echo "  install-api   Install with API dependencies"
	@echo "  test          Run tests locally"
	@echo "  lint          Run linting locally"
	@echo "  format        Format code locally"
	@echo "  clean         Clean build artifacts"
	@echo ""
	@echo "$(GREEN)🛠️  Development Setup:$(NC)"
	@echo "  setup         Complete development environment setup"
	@echo ""
	@echo "$(GREEN)🐳 Docker Commands:$(NC)"
	@echo "  build         Build all Docker images"
	@echo "  build-dev     Build development image"
	@echo "  build-api     Build API image"
	@echo "  build-train   Build training image"
	@echo ""
	@echo "$(GREEN)🏃 Service Management:$(NC)"
	@echo "  dev           Start development environment"
	@echo "  shell-dev     Dev shell with API keys"
	@echo "  shell-train   Training shell with API keys"
	@echo "  shell-api     API shell"
	@echo "  train         Start training service"
	@echo "  api           Start API service"
	@echo "  research      Start research/Jupyter service"
	@echo ""
	@echo "$(GREEN)🔧 Utilities:$(NC)"
	@echo "  logs          Show container logs"
	@echo "  down          Stop all services"
	@echo "  clean-all     Clean TextForensics resources only"
	@echo "  clean-project Clean containers and images only"
	@echo "  clean-volumes Clean TextForensics volumes only"
	@echo "  push          Push images to registry"
	@echo "  pull          Pull images from registry"
	@echo ""
	@echo "$(GREEN)🧪 Testing & Tools:$(NC)"
	@echo "  test-gpu      Test GPU availability"
	@echo "  benchmark     Run GPU benchmarks"
	@echo "  monitor       Monitor GPU usage"
	@echo "  jupyter       Start Jupyter Lab"
	@echo "  tensorboard   Start TensorBoard"
	@echo ""
	@echo "$(YELLOW)Environment Variables:$(NC)"
	@echo "  DOCKER_REGISTRY=$(DOCKER_REGISTRY)"
	@echo "  VERSION=$(VERSION)"

# Local development (without Docker)
install:
	pip install -e .

install-dev:
	pip install -r requirements/base.txt -r requirements/dev.txt
	pip install -e .

install-train:
	pip install -r requirements/base.txt -r requirements/training.txt
	pip install -e .

install-api:
	pip install -r requirements/base.txt -r requirements/api.txt
	pip install -e .

test:
	pytest tests/ -v --tb=short

lint:
	ruff check src/ tests/
	black --check src/ tests/
	mypy src/

format:
	black src/ tests/
	isort src/ tests/
	ruff check src/ tests/ --fix

clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	rm -rf .pytest_cache/
	rm -rf .mypy_cache/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

# Development setup commands
setup: build-dev dev
	@echo "$(GREEN)✅ Complete development environment setup finished!$(NC)"
	@echo "$(GREEN)🚀 Development container is now running!$(NC)"
	@echo "$(YELLOW)Ready to use:$(NC)"
	@echo "  📊 Jupyter Lab: http://localhost:8888"
	@echo "  📈 TensorBoard: http://localhost:6006"
	@echo "  🔍 Wandb: http://localhost:8097"
	@echo ""
	@echo "$(BLUE)Next step:$(NC)"
	@echo "  make shell    # Get interactive shell in container"

# Docker build commands
build: build-dev build-api build-train
	@echo "$(GREEN)✅ All images built successfully$(NC)"

build-dev:
	@echo "$(BLUE)🔨 Building development image...$(NC)"
	DOCKER_BUILDKIT=1 docker-compose -f $(COMPOSE_FILE) build textforensics-dev
	@echo "$(GREEN)✅ Development image built: $(DOCKER_REGISTRY)/textforensics-dev:$(VERSION)$(NC)"

build-api:
	@echo "$(BLUE)🔨 Building API image...$(NC)"
	DOCKER_BUILDKIT=1 docker-compose -f $(COMPOSE_FILE) build textforensics-api
	@echo "$(GREEN)✅ API image built: $(DOCKER_REGISTRY)/textforensics-api:$(VERSION)$(NC)"

build-train:
	@echo "$(BLUE)🔨 Building training image...$(NC)"
	DOCKER_BUILDKIT=1 docker-compose -f $(COMPOSE_FILE) build textforensics-train
	@echo "$(GREEN)✅ Training image built: $(DOCKER_REGISTRY)/textforensics-train:$(VERSION)$(NC)"

# Service management
dev:
	@echo "$(BLUE)🚀 Starting development environment...$(NC)"
	docker-compose -f $(COMPOSE_FILE) up -d $(SERVICE_DEV)
	@echo "$(GREEN)✅ Development environment started!$(NC)"
	@echo "$(YELLOW)📊 Jupyter Lab: http://localhost:8888$(NC)"
	@echo "$(YELLOW)📈 TensorBoard: http://localhost:6006$(NC)"
	@echo "$(YELLOW)🔍 Wandb: http://localhost:8097$(NC)"

shell:
	@echo "$(BLUE)🐚 Starting interactive bash shell...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_DEV) bash

shell-dev:
	@echo "$(BLUE)🐚 Starting dev shell with API keys...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec \
		-e GITHUB_TOKEN="$$GITHUB_TOKEN" \
		-e HF_TOKEN="$$HF_TOKEN" \
		-e WANDB_API_KEY="$$WANDB_API_KEY" \
		$(SERVICE_DEV) bash

shell-train:
	@echo "$(BLUE)🐚 Starting training shell with API keys...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec \
		-e HF_TOKEN="$$HF_TOKEN" \
		-e WANDB_API_KEY="$$WANDB_API_KEY" \
		$(SERVICE_TRAIN) bash

shell-api:
	@echo "$(BLUE)🐚 Starting API shell...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_API) bash

train:
	@echo "$(BLUE)🎯 Starting training service...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile training up $(SERVICE_TRAIN)

api:
	@echo "$(BLUE)🌐 Starting API service...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile api up -d $(SERVICE_API)
	@echo "$(GREEN)✅ API service started at http://localhost:8000$(NC)"

research:
	@echo "$(BLUE)🔬 Starting research environment...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile research up -d textforensics-research
	@echo "$(GREEN)✅ Jupyter Lab available at http://localhost:8888$(NC)"

# Utility commands
logs:
	docker-compose -f $(COMPOSE_FILE) logs -f

logs-dev:
	docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE_DEV)

logs-train:
	docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE_TRAIN)

down:
	@echo "$(YELLOW)🛑 Stopping all services...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down

# Safe cleanup commands that only affect TextForensics
clean-project: down
	@echo "$(YELLOW)🧹 Cleaning TextForensics containers and images only...$(NC)"
	# Remove only TextForensics containers
	-docker rm -f $$(docker ps -aq --filter "name=textforensics" 2>/dev/null) 2>/dev/null || true
	# Remove only TextForensics images
	-docker rmi -f $$(docker images -q --filter "reference=*textforensics*" 2>/dev/null) 2>/dev/null || true
	@echo "$(GREEN)✅ TextForensics cleanup complete$(NC)"

clean-volumes:
	@echo "$(YELLOW)🗂️  Removing TextForensics volumes only...$(NC)"
	-docker volume rm textforensics-data textforensics-logs textforensics-models textforensics-cache bash-history 2>/dev/null || true
	@echo "$(GREEN)✅ TextForensics volumes removed$(NC)"

# Safe default cleanup (replaces old clean-all)
clean-all: clean-project clean-volumes
	@echo "$(GREEN)✅ Safe TextForensics cleanup complete$(NC)"

# DANGEROUS: Only use if you understand the impact
clean-all-system: down
	@echo "$(RED)⚠️  WARNING: This will remove ALL unused Docker resources system-wide!$(NC)"
	@echo "$(RED)This affects other users and projects on this machine.$(NC)"
	@read -p "Are you absolutely sure? Type 'YES' to continue: " confirm && [ "$$confirm" = "YES" ]
	docker-compose -f $(COMPOSE_FILE) down -v --remove-orphans
	docker system prune -f
	docker volume prune -f
	@echo "$(RED)🧹 System-wide cleanup complete$(NC)"

# Registry operations
push: build
	@echo "$(BLUE)📤 Pushing images to $(DOCKER_REGISTRY)...$(NC)"
	docker push $(DOCKER_REGISTRY)/textforensics-dev:$(VERSION)
	docker push $(DOCKER_REGISTRY)/textforensics-api:$(VERSION)
	docker push $(DOCKER_REGISTRY)/textforensics-train:$(VERSION)
	@echo "$(GREEN)✅ All images pushed successfully$(NC)"

pull:
	@echo "$(BLUE)📥 Pulling images from $(DOCKER_REGISTRY)...$(NC)"
	docker pull $(DOCKER_REGISTRY)/textforensics-dev:$(VERSION)
	docker pull $(DOCKER_REGISTRY)/textforensics-api:$(VERSION)
	docker pull $(DOCKER_REGISTRY)/textforensics-train:$(VERSION)
	@echo "$(GREEN)✅ Images pulled successfully$(NC)"

# GPU testing and utilities
test-gpu:
	@echo "$(BLUE)🧪 Testing GPU availability...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_DEV) \
		python -c "import torch; print(f'✅ CUDA Available: {torch.cuda.is_available()}'); print(f'✅ GPU Count: {torch.cuda.device_count()}'); print(f'✅ GPU Name: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"No GPU\"}')"

benchmark:
	@echo "$(BLUE)📊 Running GPU benchmarks...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_DEV) \
		python scripts/training/benchmark_gpu.py

monitor:
	@echo "$(BLUE)📈 Starting GPU monitoring...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_DEV) \
		python scripts/monitoring/monitor_gpu.py

jupyter:
	@echo "$(BLUE)📊 Starting Jupyter Lab...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_DEV) jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root

tensorboard:
	@echo "$(BLUE)📈 Starting TensorBoard...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_DEV) tensorboard --logdir=outputs/logs --host=0.0.0.0 --port=6006

# Health checks
health:
	@echo "$(BLUE)🏥 Checking service health...$(NC)"
	docker-compose -f $(COMPOSE_FILE) ps
	@echo "$(GREEN)✅ Health check complete$(NC)"

# Development workflow shortcuts
quick-test: build-dev
	@echo "$(BLUE)⚡ Running quick training test...$(NC)"
	docker-compose -f $(COMPOSE_FILE) run --rm $(SERVICE_DEV) \
		python scripts/training/train.py +experiment=quick_test training.max_epochs=1

full-train: build-train
	@echo "$(BLUE)🎯 Starting full training pipeline...$(NC)"
	docker-compose -f $(COMPOSE_FILE) --profile training up $(SERVICE_TRAIN)

# CI/CD helpers
ci-build:
	@echo "$(BLUE)🤖 CI: Building all images...$(NC)"
	DOCKER_BUILDKIT=1 make build
	@echo "$(GREEN)✅ CI: Build complete$(NC)"

ci-test:
	@echo "$(BLUE)🤖 CI: Running tests...$(NC)"
	docker-compose -f $(COMPOSE_FILE) run --rm $(SERVICE_DEV) pytest tests/ -v
	@echo "$(GREEN)✅ CI: Tests passed$(NC)"

ci-deploy: ci-build push
	@echo "$(GREEN)🚀 CI: Deployment complete$(NC)"

# Show environment info
env-info:
	@echo "$(BLUE)🔍 Environment Information:$(NC)"
	@echo "Docker Registry: $(DOCKER_REGISTRY)"
	@echo "Version: $(VERSION)"
	@echo "Compose File: $(COMPOSE_FILE)"
	@echo "Development Service: $(SERVICE_DEV)"
	@echo "Training Service: $(SERVICE_TRAIN)"
	@echo "API Service: $(SERVICE_API)"
