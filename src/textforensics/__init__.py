"""
TextForensics: Neural Text Forensics Platform

A comprehensive platform for text forensics, including style analysis,
plagiarism detection, and style transfer using unified neural architectures.
"""

__version__ = "0.1.0"

# Core model imports (only import what actually exists)
from .models import (
    BaseTextForensicsModel,
    TextForensicsConfig,
    TextForensicsUnifiedModel,
)

# Pipeline imports (only import what actually exists)
from .pipelines import TrainingPipeline

# Utility imports (explicit imports instead of wildcard)
from .utils import load_checkpoint, save_checkpoint, setup_logging

__all__ = [
    # Models
    "TextForensicsUnifiedModel",
    "TextForensicsConfig",
    "BaseTextForensicsModel",
    # Pipelines
    "TrainingPipeline",
    # Utils
    "setup_logging",
    "save_checkpoint",
    "load_checkpoint",
    # Version
    "__version__",
]
