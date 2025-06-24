# ==============================================================================
# TextForensics GPU Development Environment - Multi-stage Dockerfile
# Base: Ubuntu 24.04 (lightweight approach inspired by fpl_prediction)
# Architecture: Base -> Development/Training/Production stages
# GPU: RTX 5070 Ti optimized without heavy nvidia/cuda base image
# ==============================================================================

# ==============================================================================
# BASE STAGE - Common dependencies for all stages
# ==============================================================================
FROM ubuntu:24.04 AS base

# System setup - Core environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Berlin \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1

# Define cleanup macro - Used after major installations to reduce layer size
ENV CLEANUP_CMD="apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache/pip && find /usr/local -name '*.pyc' -delete"

# GPU environment variables - RTX 5070 Ti optimizations
ENV CUDA_VISIBLE_DEVICES=0 \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    TORCH_CUDA_ARCH_LIST="8.9+PTX" \
    CUDA_LAUNCH_BLOCKING=0 \
    TORCH_CUDNN_V8_API_ENABLED=1

# Install system dependencies
RUN echo "Installing system packages..." && \
    apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    build-essential \
    cmake \
    ninja-build \
    openssh-client \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    btop \
    tmux \
    screen \
    unzip \
    zip \
    tree \
    netcat-openbsd \
    iproute2 \
    net-tools \
    iputils-ping \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    sudo \
    ca-certificates \
    gnupg && \
    eval "$CLEANUP_CMD"

# Install CUDA toolkit
RUN echo "Installing CUDA toolkit..." && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get install -y cuda-toolkit-12-9 && \
    eval "$CLEANUP_CMD"

# Set CUDA environment
ENV PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Install Node.js
RUN echo "Installing Node.js..." && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    eval "$CLEANUP_CMD"

# Configure timezone
RUN echo "Configuring timezone..." && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Configure Python alternatives
RUN echo "Configuring Python alternatives..." && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install starship prompt
RUN echo "Installing Starship prompt..." && \
    curl -sS https://starship.rs/install.sh | sh -s -- --yes && \
    echo '' >> ~/.bashrc && \
    echo '# Initialize Starship prompt' >> ~/.bashrc && \
    echo 'eval "$(starship init bash)"' >> ~/.bashrc && \
    eval "$CLEANUP_CMD"

# Set working directory
WORKDIR /workspace

# Install PyTorch
RUN echo "Installing PyTorch..." && \
    pip install --no-cache-dir --break-system-packages torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 && \
    eval "$CLEANUP_CMD"

# Install build dependencies
RUN echo "Installing build dependencies..." && \
    pip install --no-cache-dir --break-system-packages packaging wheel setuptools && \
    eval "$CLEANUP_CMD"

# Install base dependencies
COPY requirements/base.txt requirements/base.txt
RUN echo "Installing base dependencies..." && \
    pip install --no-cache-dir --break-system-packages -r requirements/base.txt && \
    eval "$CLEANUP_CMD"

# Copy and install project
COPY . .
RUN echo "Installing project..." && \
    pip install --break-system-packages -e . && \
    eval "$CLEANUP_CMD"

# ==============================================================================
# DEVELOPMENT STAGE - Full development environment with Jupyter, testing tools
# ==============================================================================
FROM base AS development

# Install development dependencies
COPY requirements/dev.txt requirements/dev.txt
RUN echo "Installing development dependencies..." && \
    pip install --no-cache-dir --break-system-packages -r requirements/dev.txt && \
    eval "$CLEANUP_CMD"

# Expose ports for development services
EXPOSE 8888 6006 8097 8000 7860

CMD ["bash"]

# ==============================================================================
# TRAINING STAGE - Optimized for ML training workloads
# ==============================================================================
FROM base AS training

# Install training dependencies
COPY requirements/training.txt requirements/training.txt
RUN echo "Installing training dependencies..." && \
    pip install --no-cache-dir --break-system-packages -r requirements/training.txt && \
    eval "$CLEANUP_CMD"

# Training-specific optimizations
ENV TORCH_CUDNN_BENCHMARK=1

CMD ["python", "scripts/training/train.py"]

# ==============================================================================
# PRODUCTION STAGE - Minimal deployment image for API serving
# ==============================================================================
FROM base AS production

# Install API dependencies
COPY requirements/api.txt requirements/api.txt
RUN echo "Installing API dependencies..." && \
    pip install --no-cache-dir --break-system-packages -r requirements/api.txt && \
    eval "$CLEANUP_CMD"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import torch; assert torch.cuda.is_available()" || exit 1

CMD ["uvicorn", "textforensics.api:app", "--host", "0.0.0.0", "--port", "8000"]

# ==============================================================================
# Build Instructions:
# docker build --target development -t textforensics-dev:$(grep VERSION .env | cut -d= -f2) .
# docker build --target training -t textforensics-train:$(grep VERSION .env | cut -d= -f2) .
# docker build --target production -t textforensics-api:$(grep VERSION .env | cut -d= -f2) .
# ==============================================================================
