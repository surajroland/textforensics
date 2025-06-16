# TextForensics GPU Development Environment
# Optimized for Ryzen 9 9950X3D + RTX 5070 Ti (16GB GDDR7)

# Use latest NVIDIA PyTorch container with CUDA 12.6
FROM nvcr.io/nvidia/pytorch:24.12-py3

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
    # LaTeX for notebooks
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.12 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install Node.js for Jupyter Lab extensions
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

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

# Install Hydra and configuration management
RUN pip install \
    hydra-core==1.3.2 \
    omegaconf==2.3.0 \
    python-dotenv==1.0.0

# Install ML utilities and monitoring
RUN pip install \
    wandb==0.18.6 \
    tensorboard==2.18.0 \
    mlflow==2.9.2 \
    neptune==1.9.1 \
    nvitop

# Install data and evaluation libraries
RUN pip install \
    datasets==3.0.0 \
    evaluate==0.4.2 \
    nltk==3.8.1 \
    spacy==3.7.2 \
    scikit-learn==1.4.0 \
    pandas==2.1.4 \
    numpy==1.26.2

# Install visualization and UI
RUN pip install \
    matplotlib==3.8.2 \
    seaborn==0.13.0 \
    plotly==5.18.0 \
    rich==13.7.0 \
    typer==0.9.0

# Install Jupyter ecosystem
RUN pip install \
    jupyter==1.1.1 \
    jupyterlab==4.3.0 \
    ipywidgets==8.1.1 \
    jupyterlab-git==0.50.0 \
    jupyterlab_code_formatter==2.2.1

# Install development tools
RUN pip install \
    black==24.10.0 \
    ruff==0.7.4 \
    mypy==1.13.0 \
    pytest==8.3.3 \
    pytest-cov==6.0.0 \
    pre-commit==4.0.1 \
    isort==5.13.2

# Install API and web tools
RUN pip install \
    fastapi==0.104.1 \
    uvicorn==0.24.0 \
    gradio==4.7.1 \
    streamlit==1.29.0

# Download spaCy models
RUN python -m spacy download en_core_web_sm
RUN python -m spacy download en_core_web_lg

# Install TextForensics requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Install package in development mode
COPY . .
RUN pip install -e .

# Configure bash as default shell
RUN chsh -s /bin/bash

# Install Starship prompt (official method)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y
RUN echo 'eval "$(starship init bash)"' >> /root/.bashrc

# Set up Jupyter Lab configuration
RUN jupyter lab --generate-config
RUN echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py

# Expose ports for Jupyter, TensorBoard, wandb, API
EXPOSE 8888 6006 8097 8000 7860

# Set working directory
WORKDIR /workspace

# Default command
CMD ["bash"]