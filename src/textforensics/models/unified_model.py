"""TextForensics Unified Model Implementation"""

from typing import Any, Dict, Optional

import torch
import torch.nn as nn
from transformers import BertConfig, BertModel

from .base import BaseTextForensicsModel, TextForensicsConfig


class TextForensicsUnifiedModel(BaseTextForensicsModel):
    """
    Unified multi-task model for text forensics.

    Supports multiple text forensics tasks through a shared backbone
    and specialized task heads.
    """

    def __init__(self, config: TextForensicsConfig) -> None:
        super().__init__(config)

        # Shared backbone encoder
        bert_config = BertConfig(
            vocab_size=config.vocab_size,
            hidden_size=config.hidden_size,
            num_hidden_layers=config.num_hidden_layers,
            num_attention_heads=config.num_attention_heads,
            intermediate_size=config.intermediate_size,
            hidden_dropout_prob=config.hidden_dropout_prob,
            attention_probs_dropout_prob=config.attention_probs_dropout_prob,
            max_position_embeddings=config.max_position_embeddings,
        )

        self.backbone = BertModel(bert_config)

        # Style encoder
        self.style_encoder = nn.Sequential(
            nn.Linear(config.hidden_size, config.style_encoder_dim),
            nn.GELU(),
            nn.LayerNorm(config.style_encoder_dim),
        )

        # Task heads (will be populated based on config)
        self.task_heads = nn.ModuleDict()
        self._build_task_heads(config.task_heads)

        # Initialize weights
        self.post_init()

    def _build_task_heads(self, task_heads_config: Dict[str, Any]) -> None:
        """Build task heads based on configuration"""

        for task_name, task_config in task_heads_config.items():
            if task_config.get("enabled", True):
                if task_name == "style_classification":
                    self.task_heads[task_name] = self._build_classification_head(
                        task_config
                    )
                elif task_name == "style_transfer":
                    self.task_heads[task_name] = self._build_generation_head(
                        task_config
                    )
                elif task_name == "anomaly_detection":
                    self.task_heads[task_name] = self._build_binary_classification_head(
                        task_config
                    )
                elif task_name == "similarity_scoring":
                    self.task_heads[task_name] = self._build_similarity_head(
                        task_config
                    )

    def _build_classification_head(self, config: Dict[str, Any]) -> nn.Module:
        """Build classification head"""
        layers = []
        input_dim = self.config.style_encoder_dim

        for hidden_dim in config.get("hidden_dims", []):
            layers.extend(
                [
                    nn.Linear(input_dim, hidden_dim),
                    nn.ReLU(),
                    nn.Dropout(config.get("dropout", 0.1)),
                ]
            )
            input_dim = hidden_dim

        layers.append(nn.Linear(input_dim, config["num_classes"]))
        return nn.Sequential(*layers)

    def _build_generation_head(self, config: Dict[str, Any]) -> nn.Module:
        """Build generation head (placeholder for now)"""
        return nn.Linear(self.config.style_encoder_dim, config["vocab_size"])

    def _build_binary_classification_head(self, config: Dict[str, Any]) -> nn.Module:
        """Build binary classification head"""
        return nn.Sequential(
            nn.Linear(self.config.style_encoder_dim, config["hidden_dims"][0]),
            nn.ReLU(),
            nn.Dropout(config.get("dropout", 0.1)),
            nn.Linear(config["hidden_dims"][0], 1),
            nn.Sigmoid(),
        )

    def _build_similarity_head(self, config: Dict[str, Any]) -> nn.Module:
        """Build similarity scoring head"""
        return nn.Identity()  # Use style embeddings directly

    def forward(
        self,
        input_ids: torch.Tensor,
        attention_mask: Optional[torch.Tensor] = None,
        task: Optional[str] = None,
        **kwargs: Any,
    ) -> Dict[str, torch.Tensor]:
        """Forward pass through the unified model"""

        # Get backbone representations
        outputs = self.backbone(
            input_ids=input_ids, attention_mask=attention_mask, return_dict=True
        )

        # Extract style embeddings
        sequence_output = outputs.last_hidden_state
        pooled_output = outputs.pooler_output
        style_embeddings = self.style_encoder(pooled_output)

        results = {
            "style_embeddings": style_embeddings,
            "sequence_output": sequence_output,
            "pooled_output": pooled_output,
        }

        # Apply task-specific heads
        if task and task in self.task_heads:
            task_output = self.task_heads[task](style_embeddings)
            results[f"{task}_output"] = task_output
        else:
            # Apply all enabled task heads
            for task_name, task_head in self.task_heads.items():
                task_output = task_head(style_embeddings)
                results[f"{task_name}_output"] = task_output

        return results

    def get_style_embeddings(
        self, input_ids: torch.Tensor, attention_mask: Optional[torch.Tensor] = None
    ) -> torch.Tensor:
        """Extract style embeddings"""
        outputs = self.backbone(
            input_ids=input_ids, attention_mask=attention_mask, return_dict=True
        )
        return self.style_encoder(outputs.pooler_output)
