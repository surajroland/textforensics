"""Utility functions for TextForensics"""

import logging
from pathlib import Path

import torch
from omegaconf import DictConfig


def setup_logging(config: DictConfig) -> logging.Logger:
    """Setup logging configuration"""
    logger = logging.getLogger("textforensics")
    logger.setLevel(getattr(logging, config.get("log_level", "INFO")))

    # Create handler if not already exists
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger


def save_checkpoint(
    model: torch.nn.Module,
    optimizer: torch.optim.Optimizer,
    scheduler: torch.optim.lr_scheduler._LRScheduler,
    epoch: int,
    loss: float,
    path: Path,
) -> None:
    """Save model checkpoint"""
    path.parent.mkdir(parents=True, exist_ok=True)

    checkpoint = {
        "epoch": epoch,
        "model_state_dict": model.state_dict(),
        "optimizer_state_dict": optimizer.state_dict(),
        "scheduler_state_dict": scheduler.state_dict() if scheduler else None,
        "loss": loss,
    }

    torch.save(checkpoint, path)


def load_checkpoint(path: Path) -> dict:
    """Load model checkpoint"""
    return torch.load(path, map_location="cpu")
