import pytest
import torch
from pathlib import Path

# Test configuration
@pytest.fixture
def sample_config():
    """Sample configuration for testing"""
    from textforensics.models.base import TextForensicsConfig
    return TextForensicsConfig(
        vocab_size=1000,  # Smaller for testing
        hidden_size=128,
        num_hidden_layers=2,
        num_attention_heads=4,
        task_heads={
            'style_classification': {
                'enabled': True,
                'num_classes': 3,
                'hidden_dims': [64],
                'dropout': 0.1
            }
        }
    )

@pytest.fixture
def device():
    """Device for testing"""
    return torch.device("cuda" if torch.cuda.is_available() else "cpu")
