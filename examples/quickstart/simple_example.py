#!/usr/bin/env python3
"""
Simple TextForensics Example

Demonstrates basic usage without configuration files.
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "src"))

import torch

from textforensics.models.base import TextForensicsConfig
from textforensics.models.unified_model import TextForensicsUnifiedModel


def main():
    """Simple example of TextForensics usage"""

    print("🔍 TextForensics Simple Example")
    print("=" * 40)

    # Create model configuration
    config = TextForensicsConfig(
        vocab_size=30522,
        hidden_size=768,
        num_hidden_layers=12,
        num_attention_heads=12,
        task_heads={
            "style_classification": {
                "enabled": True,
                "num_classes": 3,
                "hidden_dims": [512, 256],
                "dropout": 0.3,
            }
        },
    )

    # Initialize model
    print("🏗️  Initializing model...")
    model = TextForensicsUnifiedModel(config)

    # Example texts (dummy token IDs)
    print("\n📖 Analyzing text styles...")

    # Create dummy input
    batch_size = 2
    seq_length = 100
    input_ids = torch.randint(0, 30522, (batch_size, seq_length))
    attention_mask = torch.ones_like(input_ids)

    # Forward pass
    outputs = model(input_ids=input_ids, attention_mask=attention_mask)

    print(f"Style embeddings shape: {outputs['style_embeddings'].shape}")
    print(f"Available outputs: {list(outputs.keys())}")

    print("\n✅ Example completed!")
    print("\n💡 To train the model, run:")
    print("   python scripts/train.py +experiment=quick_test")


if __name__ == "__main__":
    main()
