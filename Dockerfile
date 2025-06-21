# TextForensics GPU Development Environment
# Multi-stage build optimized for Ryzen 9 9950X3D + RTX 5070 Ti (16GB GDDR7)

# ==============================================================================
# BASE STAGE - Common dependencies for all stages
# ==============================================================================
FROM nvidia/cuda:12.9.0-devel-ubuntu24.04 AS base

# Build arguments
ARG BUILDKIT_INLINE_CACHE=1
ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
ARG SETUP_DEV_CONFIG=true
ARG USER_ID=1000
ARG GROUP_ID=1000

# Set environment variables for optimal GPU usage
ENV CUDA_VISIBLE_DEVICES=0 \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

# GPU-specific optimizations for RTX 5070 Ti
ENV TORCH_CUDA_ARCH_LIST="8.9+PTX" \
    CUDA_LAUNCH_BLOCKING=0 \
    TORCH_CUDNN_V8_API_ENABLED=1

# Python and build optimizations
ENV TZ=Europe/Berlin \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1

# ==============================================================================
# SYSTEM DEPENDENCIES INSTALLATION
# ==============================================================================
# Install system dependencies, Node.js, and configure Python in one optimized layer
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Update package lists and install system packages
    apt-get update && apt-get install -y --no-install-recommends \
        # Python and development tools
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
        build-essential \
        cmake \
        ninja-build \
        # Version control and utilities
        git \
        curl \
        wget \
        # Text editors and system tools
        vim \
        nano \
        htop \
        tmux \
        screen \
        nvtop \
        # Archive and networking tools
        unzip \
        zip \
        tree \
        netcat-openbsd \
        iproute2 \
        net-tools \
        iputils-ping \
        # LaTeX for documentation
        texlive-xetex \
        texlive-fonts-recommended \
        texlive-plain-generic \
        # System administration
        sudo \
        ca-certificates \
        gnupg && \
    # Install Node.js for Jupyter Lab extensions
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    # Configure Python 3.12 as default
    update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    # Cleanup to minimize layer size
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get autoremove -y

WORKDIR /workspace

# ==============================================================================
# PYTHON PACKAGES INSTALLATION
# ==============================================================================
RUN echo "Using system pip with PIP_BREAK_SYSTEM_PACKAGES=1"

# Install PyTorch ecosystem with latest CUDA 12.8 support
RUN pip install --no-cache-dir --break-system-packages \
        torch \
        torchvision \
        torchaudio \
        --index-url https://download.pytorch.org/whl/cu128

# Install core transformers and ML libraries
RUN pip install --no-cache-dir --break-system-packages \
        transformers==4.46.0 \
        accelerate==1.1.0 \
        bitsandbytes==0.44.0

# Install advanced ML libraries (might need compilation)
RUN pip install --no-cache-dir --break-system-packages xformers==0.0.28.post2
RUN pip install --no-cache-dir --break-system-packages flash-attn==2.6.3
RUN pip install --no-cache-dir --break-system-packages deepspeed==0.15.4 fairscale==0.4.13

# Install configuration and monitoring tools
RUN pip install --no-cache-dir --break-system-packages \
        hydra-core==1.3.2 \
        omegaconf==2.3.0 \
        python-dotenv==1.0.0 \
        wandb==0.18.6 \
        tensorboard==2.18.0 \
        mlflow==2.9.2 \
        neptune==1.9.1 \
        nvitop

# Install data science libraries
RUN pip install --no-cache-dir --break-system-packages \
        numpy==1.26.2 \
        pandas==2.1.4 \
        datasets==3.0.0 \
        evaluate==0.4.2 \
        nltk==3.8.1 \
        spacy==3.7.2 \
        scikit-learn==1.4.0

# Install visualization libraries
RUN pip install --no-cache-dir --break-system-packages \
        matplotlib==3.8.2 \
        seaborn==0.13.0 \
        plotly==5.18.0 \
        rich==13.7.0 \
        typer==0.9.0

# Download spaCy language models
RUN python -m spacy download en_core_web_sm && \
    python -m spacy download en_core_web_lg

# Clean up pip cache and temporary files
RUN rm -rf ~/.cache/pip /tmp/* /var/tmp/* && \
    find /usr/local -name "*.pyc" -delete && \
    find /usr/local -name "__pycache__" -exec rm -rf {} +

# ==============================================================================
# PROJECT INSTALLATION
# ==============================================================================
# Install TextForensics package and project requirements
COPY requirements.txt .
COPY . .
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -e . && \
    # Clean up after installation
    rm -rf ~/.cache/pip /tmp/* /var/tmp/* && \
    find /usr/local -name "*.pyc" -delete

# ==============================================================================
# SHELL AND ENVIRONMENT CONFIGURATION
# ==============================================================================
# Install and configure Starship prompt and development environment
RUN curl -L https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz -o starship.tar.gz && \
    tar xzf starship.tar.gz && \
    mv starship /usr/local/bin/ && \
    rm starship.tar.gz && \
    # Create starship initialization script
    echo '#!/bin/bash\n\
mkdir -p ~/.cache/starship 2>/dev/null || mkdir -p /tmp/starship-$USER\n\
export STARSHIP_CACHE=${HOME}/.cache/starship 2>/dev/null || export STARSHIP_CACHE=/tmp/starship-$USER\n\
eval "$(starship init bash)"' > /usr/local/bin/init-starship.sh && \
    chmod +x /usr/local/bin/init-starship.sh && \
    # Configure global bashrc to use Starship
    echo 'source /usr/local/bin/init-starship.sh' >> /etc/bash.bashrc && \
    # Set up Jupyter Lab configuration
    mkdir -p /etc/jupyter && \
    echo 'c.ServerApp.ip = "0.0.0.0"\n\
c.ServerApp.allow_root = True\n\
c.ServerApp.open_browser = False' > /etc/jupyter/jupyter_lab_config.py && \
    # Create Jupyter initialization script
    echo '#!/bin/bash\n\
mkdir -p ~/.jupyter\n\
cp /etc/jupyter/jupyter_lab_config.py ~/.jupyter/ 2>/dev/null || true' > /usr/local/bin/init-jupyter.sh && \
    chmod +x /usr/local/bin/init-jupyter.sh

# ==============================================================================
# FINAL BASE CLEANUP
# ==============================================================================
# Remove unnecessary files to minimize base image size
RUN rm -rf /root/.cache/pip \
           /tmp/* \
           /var/tmp/* \
           /var/cache/apt/* \
           /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/locale/* && \
    find /usr/local -name "*.pyc" -delete && \
    find /usr/local -name "__pycache__" -exec rm -rf {} + && \
    apt-get autoremove -y && \
    apt-get autoclean

# Expose ports for development services
EXPOSE 8888 6006 8097 8000 7860

# ==============================================================================
# DEVELOPMENT STAGE - Full development environment
# ==============================================================================
FROM base AS development

# Install development and testing tools
RUN pip install --no-cache-dir \
        # Jupyter ecosystem
        jupyter==1.1.1 \
        jupyterlab==4.3.0 \
        ipywidgets==8.1.1 \
        jupyterlab-git==0.50.0 \
        jupyterlab_code_formatter==2.2.1 \
        # Code quality tools
        black==24.10.0 \
        ruff==0.7.4 \
        mypy==1.13.0 \
        pytest==8.3.3 \
        pytest-cov==6.0.0 \
        pre-commit==4.0.1 \
        isort==5.13.2 \
        # API and web frameworks
        fastapi==0.104.1 \
        uvicorn==0.24.0 \
        gradio==4.7.1 \
        streamlit==1.29.0 && \
    # Create container initialization script
    echo '#!/bin/bash\n\
source /usr/local/bin/init-starship.sh\n\
source /usr/local/bin/init-jupyter.sh\n\
exec "$@"' > /usr/local/bin/container-init.sh && \
    chmod +x /usr/local/bin/container-init.sh && \
    # Development stage cleanup
    rm -rf ~/.cache/pip /tmp/* /var/tmp/* && \
    find /usr/local -name "*.pyc" -delete

# Default command for development
CMD ["bash"]

# ==============================================================================
# PRODUCTION STAGE - Minimal deployment image
# ==============================================================================
FROM base AS production

# Install only production API dependencies
RUN pip install --no-cache-dir \
        fastapi==0.104.1 \
        uvicorn==0.24.0 && \
    # Aggressive production cleanup
    rm -rf ~/.cache/pip \
           /tmp/* \
           /var/tmp/* \
           /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/locale/* && \
    find /usr/local -name "*.pyc" -delete && \
    find /usr/local -name "__pycache__" -exec rm -rf {} + && \
    apt-get autoremove -y && \
    apt-get autoclean

# Health check for production deployments
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import torch; assert torch.cuda.is_available()" || exit 1

# Production API command
CMD ["uvicorn", "textforensics.api:app", "--host", "0.0.0.0", "--port", "8000"]

# ==============================================================================
# TRAINING STAGE - Optimized for ML training workloads
# ==============================================================================
FROM base AS training

# Install training-specific optimization tools
RUN pip install --no-cache-dir \
        wandb==0.18.6 \
        tensorboard==2.18.0 \
        torch-tb-profiler && \
    # Final training stage cleanup
    rm -rf ~/.cache/pip \
           /tmp/* \
           /var/tmp/* \
           /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/locale/* && \
    find /usr/local -name "*.pyc" -delete && \
    find /usr/local -name "__pycache__" -exec rm -rf {} + && \
    apt-get autoremove -y && \
    apt-get autoclean

# Training-specific GPU optimizations
ENV CUDA_LAUNCH_BLOCKING=0 \
    TORCH_CUDNN_BENCHMARK=1

# Default training command
CMD ["python", "scripts/training/train.py"]
