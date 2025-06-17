# TextForensics GPU Development Environment
# Multi-stage build optimized for Ryzen 9 9950X3D + RTX 5070 Ti (16GB GDDR7)

# Base stage with common dependencies
FROM nvcr.io/nvidia/pytorch:24.12-py3 AS base

# Build arguments
ARG BUILDKIT_INLINE_CACHE=1
ARG DEBIAN_FRONTEND=noninteractive

# Set environment variables for optimal GPU usage
ENV CUDA_VISIBLE_DEVICES=0
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# GPU-specific optimizations for RTX 5070 Ti
ENV TORCH_CUDA_ARCH_LIST="8.9+PTX"
ENV CUDA_LAUNCH_BLOCKING=0
ENV TORCH_CUDNN_V8_API_ENABLED=1

# Set timezone
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Python and build tools
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    build-essential \
    cmake \
    ninja-build \
    # Development tools
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    tmux \
    screen \
    # GPU monitoring
    nvtop \
    # File utilities
    unzip \
    zip \
    tree \
    # Network tools
    netcat-openbsd \
    iproute2 \
    net-tools \
    iputils-ping \
    # LaTeX for notebooks
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set Python 3.12 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install Node.js for Jupyter Lab extensions
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

WORKDIR /workspace

# Upgrade pip and install build tools
RUN pip install --upgrade pip setuptools wheel

# Install PyTorch 2.7+ with CUDA 12.8 support (latest stable - optimized for RTX 5070 Ti)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# Install transformers and ML ecosystem
RUN pip install \
    # Core ML libraries
    transformers==4.46.0 \
    accelerate==1.1.0 \
    bitsandbytes==0.44.0 \
    xformers==0.0.28.post2 \
    # Flash Attention for RTX 5070 Ti
    flash-attn==2.6.3 \
    # Advanced optimization
    deepspeed==0.15.4 \
    fairscale==0.4.13

# Install core dependencies in smaller groups to identify conflicts
# Group 1: Configuration management
RUN pip install \
    hydra-core==1.3.2 \
    omegaconf==2.3.0 \
    python-dotenv==1.0.0

# Group 2: ML monitoring (most likely culprit for conflicts)
RUN pip install --no-deps wandb==0.18.6 && \
    pip install tensorboard==2.18.0 && \
    pip install mlflow==2.9.2 && \
    pip install neptune==1.9.1 && \
    pip install nvitop

# Group 3: Data libraries (install numpy first, then pandas)
RUN pip install numpy==1.26.2 && \
    pip install pandas==2.1.4

# Group 4: ML and evaluation libraries
RUN pip install \
    datasets==3.0.0 \
    evaluate==0.4.2 \
    nltk==3.8.1 \
    spacy==3.7.2 \
    scikit-learn==1.4.0

# Group 5: Visualization and UI (matplotlib can be tricky)
RUN pip install matplotlib==3.8.2 && \
    pip install \
    seaborn==0.13.0 \
    plotly==5.18.0 \
    rich==13.7.0 \
    typer==0.9.0

# Download spaCy models
RUN python -m spacy download en_core_web_sm && \
    python -m spacy download en_core_web_lg

# Install TextForensics requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Install package in development mode
COPY . .
RUN pip install -e .

# Configure bash as default shell
RUN chsh -s /bin/bash

# Install Starship prompt (manual installation - more reliable than installer script)
RUN curl -L https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz -o starship.tar.gz && \
    tar xzf starship.tar.gz && \
    mv starship /usr/local/bin/ && \
    rm starship.tar.gz && \
    echo 'eval "$(starship init bash)"' >> /root/.bashrc

# Set up Jupyter Lab configuration
RUN jupyter lab --generate-config && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py

# Expose ports for Jupyter, TensorBoard, wandb, API
EXPOSE 8888 6006 8097 8000 7860

# Set working directory
WORKDIR /workspace

# Development stage - includes all development tools
FROM base AS development

# Install development tools
RUN pip install \
    # Jupyter ecosystem
    jupyter==1.1.1 \
    jupyterlab==4.3.0 \
    ipywidgets==8.1.1 \
    jupyterlab-git==0.50.0 \
    jupyterlab_code_formatter==2.2.1 \
    # Development tools
    black==24.10.0 \
    ruff==0.7.4 \
    mypy==1.13.0 \
    pytest==8.3.3 \
    pytest-cov==6.0.0 \
    pre-commit==4.0.1 \
    isort==5.13.2 \
    # API and web tools
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    gradio==4.7.1 \
    streamlit==1.29.0

# Default command for development
CMD ["bash"]

# Production stage - minimal for deployment
FROM base AS production

# Install only production API dependencies
RUN pip install \
    fastapi==0.104.1 \
    uvicorn==0.24.0

# Remove development tools and caches
RUN pip cache purge && \
    rm -rf /root/.cache/pip

# Health check for production
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import torch; assert torch.cuda.is_available()" || exit 1

# Production command
CMD ["uvicorn", "textforensics.api:app", "--host", "0.0.0.0", "--port", "8000"]

# Training stage - optimized for training workloads
FROM base AS training

# Install training-specific optimizations
RUN pip install \
    # Additional training tools
    wandb==0.18.6 \
    tensorboard==2.18.0 \
    # Performance profiling
    torch-tb-profiler

# Training-specific optimizations
ENV CUDA_LAUNCH_BLOCKING=0
ENV TORCH_CUDNN_BENCHMARK=1

# Default training command
CMD ["python", "scripts/training/train.py"]
