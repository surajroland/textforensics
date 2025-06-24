"""Base model class for TextForensics models"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

import torch
from transformers import PretrainedConfig, PreTrainedModel


class TextForensicsConfig(PretrainedConfig):
    """Configuration class for TextForensics models"""

    model_type = "textforensics"

    def __init__(
        self,
        vocab_size: int = 30522,
        hidden_size: int = 768,
        num_hidden_layers: int = 12,
        num_attention_heads: int = 12,
        intermediate_size: int = 3072,
        hidden_dropout_prob: float = 0.1,
        attention_probs_dropout_prob: float = 0.1,
        max_position_embeddings: int = 512,
        style_encoder_dim: int = 768,
        task_heads: Optional[Dict[str, Any]] = None,
        **kwargs: Any,
    ) -> None:
        super().__init__(**kwargs)

        self.vocab_size = vocab_size
        self.hidden_size = hidden_size
        self.num_hidden_layers = num_hidden_layers
        self.num_attention_heads = num_attention_heads
        self.intermediate_size = intermediate_size
        self.hidden_dropout_prob = hidden_dropout_prob
        self.attention_probs_dropout_prob = attention_probs_dropout_prob
        self.max_position_embeddings = max_position_embeddings
        self.style_encoder_dim = style_encoder_dim
        self.task_heads = task_heads or {}


class BaseTextForensicsModel(PreTrainedModel, ABC):
    """Abstract base class for all TextForensics models"""

    config_class = TextForensicsConfig
    base_model_prefix = "textforensics"

    def __init__(self, config: TextForensicsConfig) -> None:
        super().__init__(config)

    @abstractmethod
    def forward(
        self,
        input_ids: torch.Tensor,
        attention_mask: Optional[torch.Tensor] = None,
        **kwargs: Any,
    ) -> Dict[str, torch.Tensor]:
        """Forward pass - must be implemented by subclasses"""
        pass

    @abstractmethod
    def get_style_embeddings(
        self, input_ids: torch.Tensor, attention_mask: Optional[torch.Tensor] = None
    ) -> torch.Tensor:
        """Extract style embeddings - must be implemented by subclasses"""
        pass

    def save_pretrained(self, save_directory: str, **kwargs: Any) -> None:
        """Save model and configuration"""
        super().save_pretrained(save_directory, **kwargs)

    @classmethod
    def from_pretrained(cls, pretrained_model_name_or_path: str, **kwargs: Any) -> Any:
        """Load pretrained model"""
        return super().from_pretrained(pretrained_model_name_or_path, **kwargs)
