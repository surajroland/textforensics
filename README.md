# TextForensics: Neural Text Forensics Platform

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/release/python-380/)
[![PyTorch](https://img.shields.io/badge/pytorch-1.13+-red.svg)](https://pytorch.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive neural platform for text forensics, including style analysis, plagiarism detection, and style transfer using unified transformer architectures.

## 🎯 Features

- **Style Classification**: Identify authors from writing style
- **Style Transfer**: Transform text style while preserving content
- **Plagiarism Detection**: Advanced similarity detection algorithms
- **Anomaly Detection**: Identify inconsistent writing patterns
- **Multi-task Learning**: Unified model for all forensics tasks
- **Modular Architecture**: Extensible with custom components

## 🚀 Quick Start

### Prerequisites

- Docker with GPU support (NVIDIA Docker)
- WSL2 + Ubuntu 24.04 (for Windows users)
- RTX 5070 Ti or compatible GPU

### Installation

```bash
# Run the setup script
./setup_textforensics.sh textforensics

# Navigate to project
cd textforensics

# Setup development environment
bash scripts/setup_dev.sh
```

### Development with Docker GPU

```bash
# Start development environment
make dev-gpu

# Get interactive shell
make shell-gpu

# Test GPU setup
make test-gpu

# Run benchmarks for RTX 5070 Ti
make benchmark
```

### Basic Usage

```bash
# Quick training test
make train-quick

# Full training with GPU optimization
make train-gpu

# Monitor GPU during training
python scripts/monitor_gpu.py
```

### Access Development Services

- **📊 Jupyter Lab**: http://localhost:8888
- **📈 TensorBoard**: http://localhost:6006
- **🔍 Wandb**: http://localhost:8097
- **🚀 FastAPI**: http://localhost:8000

## ⚙️ Configuration

The project uses Hydra for configuration management:

```bash
# Different models
python scripts/train.py model=unified_base

# Different datasets
python scripts/train.py data=spooky_authors

# Hyperparameter sweeps
python scripts/train.py -m training.optimizer.lr=1e-4,5e-5,1e-5

# Custom experiments
python scripts/train.py +experiment=quick_test

# RTX 5070 Ti optimized settings
python scripts/train.py infrastructure/compute=rtx_5070_ti
```

## 🏗️ Architecture

TextForensics uses a unified multi-task transformer architecture:

```
Shared BERT Backbone
├── Style Encoder (768-dim embeddings)
│
├── Classification Heads
│   ├── Style Classification
│   ├── Anomaly Detection
│   └── Genre Classification
│
├── Generation Heads
│   ├── Style Transfer
│   └── Cross-Genre Transfer
│
└── Analysis Heads
    ├── Style Similarity
    ├── Consistency Tracking
    └── Temporal Evolution
```

## 🔧 Development Environment

### Hardware Optimizations
- **RTX 5070 Ti**: 16GB GDDR7 optimized
- **Ryzen 9 9950X3D**: 32-thread CPU utilization
- **Mixed Precision**: BF16 for better performance
- **Flash Attention**: Memory-efficient attention

### Tools & Features
- **VS Code Integration**: Remote containers, extensions
- **Git Graph**: Visual commit history
- **Real-time Monitoring**: GPU temp, memory, power

## 📊 Supported Datasets

- **Spooky Authors**: Kaggle dataset (3 authors)
- **SPGC**: Standardized Project Gutenberg Corpus
- **PAN Datasets**: Competition datasets for authorship analysis
- **Custom**: Support for your own datasets

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- HuggingFace Transformers for the backbone architecture
- Hydra for configuration management
- NVIDIA for PyTorch Docker containers
