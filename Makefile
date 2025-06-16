# TextForensics Makefile - GPU Optimized for RTX 5070 Ti

.PHONY: help install install-dev test lint format clean build-gpu dev-gpu shell-gpu train-gpu

help:
	@echo "🚀 TextForensics GPU Development Commands:"
	@echo "  install       Install package"
	@echo "  install-dev   Install package with development dependencies"
	@echo "  test          Run tests"
	@echo "  lint          Run linting"
	@echo "  format        Format code"
	@echo "  clean         Clean build artifacts"
	@echo ""
	@echo "🐳 Docker GPU Commands:"
	@echo "  build-gpu     Build GPU-enabled Docker image"
	@echo "  dev-gpu       Start development environment with GPU"
	@echo "  shell-gpu     Interactive Bash shell"
	@echo "  train-gpu     Run GPU training"
	@echo "  benchmark     GPU benchmarking for RTX 5070 Ti"

# Local installation
install:
	pip install -e .

install-dev:
	pip install -e ".[dev]"

test:
	pytest tests/ -v

lint:
	flake8 src/ tests/
	black --check src/ tests/

format:
	black src/ tests/
	isort src/ tests/

clean:
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	rm -rf .pytest_cache/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

# Enhanced Docker GPU Commands
build-gpu:
	@echo "🔨 Building GPU-optimized container..."
	docker-compose -f docker-compose.yml build

dev-gpu:
	@echo "🚀 Starting development environment..."
	docker-compose -f docker-compose.yml up -d textforensics-dev
	@echo "✅ Development environment started!"
	@echo "📊 Jupyter Lab: http://localhost:8888"
	@echo "📈 TensorBoard: http://localhost:6006"
	@echo "🔍 Git Graph: Available in VS Code"

shell-gpu:
	@echo "🐚 Starting interactive Bash shell..."
	docker-compose -f docker-compose.yml exec textforensics-dev bash

train-gpu:
	docker-compose -f docker-compose.yml run --rm textforensics-train

# GPU Testing and Benchmarking
test-gpu:
	docker-compose -f docker-compose.yml exec textforensics-dev \
		python -c "import torch; print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'GPU Count: {torch.cuda.device_count()}'); print(f'GPU Name: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"No GPU\"}')"

benchmark:
	docker-compose -f docker-compose.yml exec textforensics-dev \
		python scripts/benchmark_gpu.py

# Training shortcuts
train-quick:
	python scripts/train.py +experiment=quick_test

train-full:
	python scripts/train.py model=unified_base data=spooky_authors