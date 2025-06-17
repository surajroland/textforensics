#!/usr/bin/env python3
"""
TextForensics Training Script

Run training with Hydra configuration system.

Examples:
    # Basic training
    python scripts/train.py

    # Custom model and data
    python scripts/train.py model=style_mimic data=spgc

    # Hyperparameter sweep
    python scripts/train.py -m training.optimizer.lr=1e-4,5e-5,1e-5

    # Quick test
    python scripts/train.py +experiment=quick_test
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import hydra
from omegaconf import DictConfig, OmegaConf

from textforensics.pipelines import TrainingPipeline


@hydra.main(version_base=None, config_path="../conf", config_name="config")
def train(cfg: DictConfig) -> float:
    """Main training function"""

    # Print configuration
    print("🚀 Starting TextForensics Training")
    print("=" * 50)
    print("Configuration:")
    print(OmegaConf.to_yaml(cfg))
    print("=" * 50)

    # Initialize and run training pipeline
    pipeline = TrainingPipeline(cfg)
    results = pipeline.run()

    # Print results
    print("✅ Training completed!")
    print(f"Best validation loss: {results['best_val_loss']:.4f}")
    print(f"Final epoch: {results['final_epoch']}")

    # Return metric for hyperparameter optimization
    return results["best_val_loss"]


if __name__ == "__main__":
    train()
