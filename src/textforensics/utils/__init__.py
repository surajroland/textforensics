"""Utility functions for TextForensics"""

import logging
import random
from pathlib import Path
from typing import Any, Dict, Optional

import numpy as np
import torch
from omegaconf import DictConfig, OmegaConf


def setup_logging(config: DictConfig) -> logging.Logger:
    """Setup logging configuration"""
    # Create logs directory if it doesn't exist
    log_dir = Path(config.get("log_dir", "logs"))
    log_dir.mkdir(exist_ok=True)

    # Configure logging
    logging.basicConfig(
        level=getattr(logging, config.get("log_level", "INFO")),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        handlers=[
            logging.FileHandler(log_dir / "textforensics.log"),
            logging.StreamHandler(),
        ],
    )

    logger = logging.getLogger("textforensics")
    logger.info("Logging initialized")
    return logger


def get_device() -> torch.device:
    """Get the best available device"""
    if torch.cuda.is_available():
        device = torch.device("cuda")
        logger = logging.getLogger("textforensics")
        logger.info(f"Using GPU: {torch.cuda.get_device_name(0)}")
        logger.info(
            f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB"
        )
    else:
        device = torch.device("cpu")
        logging.getLogger("textforensics").info("Using CPU")
    return device


def set_seed(seed: int = 42) -> None:
    """Set random seed for reproducibility"""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)

    # For deterministic behavior (slower but reproducible)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


def count_parameters(model: torch.nn.Module) -> int:
    """Count total trainable parameters in a model"""
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


def get_model_size(model: torch.nn.Module) -> str:
    """Get human-readable model size"""
    param_count = count_parameters(model)

    if param_count >= 1e9:
        return f"{param_count / 1e9:.1f}B parameters"
    elif param_count >= 1e6:
        return f"{param_count / 1e6:.1f}M parameters"
    elif param_count >= 1e3:
        return f"{param_count / 1e3:.1f}K parameters"
    else:
        return f"{param_count} parameters"


def save_config(config: DictConfig, save_path: str) -> None:
    """Save configuration to file"""
    path = Path(save_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w") as f:
        OmegaConf.save(config, f)


def save_checkpoint(
    model: torch.nn.Module,
    optimizer: torch.optim.Optimizer,
    scheduler: Optional[torch.optim.lr_scheduler._LRScheduler],
    epoch: int,
    loss: float,
    path: Path,
) -> None:
    """Save model checkpoint with full training state"""
    path.parent.mkdir(parents=True, exist_ok=True)

    checkpoint = {
        "epoch": epoch,
        "model_state_dict": model.state_dict(),
        "optimizer_state_dict": optimizer.state_dict(),
        "scheduler_state_dict": scheduler.state_dict() if scheduler else None,
        "loss": loss,
    }

    torch.save(checkpoint, path)


def load_checkpoint(
    path: Path, model: Optional[torch.nn.Module] = None
) -> Dict[str, Any]:
    """Load model checkpoint"""
    checkpoint: Dict[str, Any] = torch.load(path, map_location="cpu")

    if model is not None:
        model.load_state_dict(checkpoint["model_state_dict"])

    return checkpoint
