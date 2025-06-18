#!/bin/bash
# TextForensics Development Environment Setup

set -e

echo "🚀 Setting up TextForensics Development Environment"
echo "💻 Hardware: Ryzen 9 9950X3D + RTX 5070 Ti"
echo "🐳 Platform: Docker + WSL2 + Ubuntu 24.04"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if nvidia-docker is available
if ! docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi > /dev/null 2>&1; then
    echo "❌ NVIDIA Docker support not available. Please install nvidia-docker2."
    exit 1
fi

echo "✅ Docker and GPU support detected"

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.base .env
    echo "⚠️  Please edit .env with your API keys before continuing"
fi

# Build the GPU development image
echo "🔨 Building GPU development image..."
make build-gpu

# Test GPU availability
echo "🧪 Testing GPU availability..."
make test-gpu

# Start development environment
echo "🚀 Starting development environment..."
make dev-gpu

echo ""
echo "✅ Development environment ready!"
echo ""
echo "🔗 Access points:"
echo "   📊 Jupyter Lab: http://localhost:8888"
echo "   📈 TensorBoard: http://localhost:6006"
echo "   🔍 Wandb: http://localhost:8097"
echo ""
echo "🐚 To get a shell:"
echo "   make shell-gpu"
echo ""
echo "🏃‍♂️ To run training:"
echo "   make train-quick    # Quick test"
echo "   make train-gpu      # Full training"
echo ""
echo "📊 To monitor GPU:"
echo "   python scripts/monitor_gpu.py"
