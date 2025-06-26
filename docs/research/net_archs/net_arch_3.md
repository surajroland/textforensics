Complete Zero-Shot Style Transfer Architecture Flow
═══════════════════════════════════════════════════════════════

INPUT PROCESSING
┌─────────────────────────────────────────────────────────────┐
│ Source: "I went to the store"                               │
│ Style: "The old man sat by the sea. He waited."           │
└─────────────────┬───────────────────────────────────────────┘
                  │
         TOKENIZATION (BERT Tokenizer)
┌─────────────────▼───────────────────────────────────────────┐
│ source_ids: [101, 1045, 2253, 2000, 1996, 3573, 102, ...]  │
│ style_ids:  [101, 1996, 2214, 2158, 2938, 2011, ...]      │
│ attention_masks: [1, 1, 1, 1, 1, 1, 1, 0, ...]            │
└─────────────────┬───────────────────────────────────────────┘
                  │
         SHARED BERT BACKBONE (ONE MODEL)
┌─────────────────▼───────────────────────────────────────────┐
│                BERT-BASE-UNCASED                            │
│                                                             │
│ source_ids → BERT → source_output.pooler_output [B, 768]   │
│ style_ids  → BERT → style_output.pooler_output [B, 768]    │
│                                                             │
│ (Same BERT weights process both inputs separately)          │
└─────────────────┬───────────────────────────────────────────┘
                  │
         STYLE ENCODER (SEQUENTIAL)
┌─────────────────▼───────────────────────────────────────────┐
│ source_pooled [B, 768] → Linear(768→768) → GELU → LayerNorm │
│ style_pooled [B, 768]  → Linear(768→768) → GELU → LayerNorm │
│                                                             │
│ Output:                                                     │
│ source_style_vector [B, 768]                               │
│ target_style_vector [B, 768]                               │
└─────────────────┬───────────────────────────────────────────┘
                  │
         GENERATION NECK (SEQUENTIAL)
┌─────────────────▼───────────────────────────────────────────┐
│              CONTENT/STYLE SEPARATION                       │
│                                                             │
│ source_style_vector [B, 768]                               │
│    ↓                                                        │
│ Content Encoder: Linear(768→512) + ReLU + Dropout          │
│    ↓                                                        │
│ content_features [B, 512]                                  │
│                                                             │
│ target_style_vector [B, 768]                               │
│    ↓                                                        │
│ Style Extractor: Linear(768→256) + Tanh                    │
│    ↓                                                        │
│ style_features [B, 256]                                    │
│                                                             │
│ CONDITIONING:                                               │
│ concat(content_features, style_features) → [B, 768]        │
│    ↓                                                        │
│ Linear(768→768) + LayerNorm                                │
│    ↓                                                        │
│ conditioned_features [B, 768]                              │
└─────────────────┬───────────────────────────────────────────┘
                  │
         STYLE TRANSFER HEAD (SEQUENTIAL)
┌─────────────────▼───────────────────────────────────────────┐
│ conditioned_features [B, 768]                              │
│    ↓                                                        │
│ Decoder Layers:                                             │
│   - Self-attention + Cross-attention                       │
│   - Feed-forward networks                                  │
│   - Layer normalization                                    │
│    ↓                                                        │
│ contextualized_features [B, seq_len, 768]                  │
│    ↓                                                        │
│ Vocabulary Projection: Linear(768→30522)                   │
│    ↓                                                        │
│ token_logits [B, seq_len, 30522]                           │
│    ↓                                                        │
│ Softmax → token_probabilities                              │
└─────────────────┬───────────────────────────────────────────┘
                  │
         OUTPUT GENERATION
┌─────────────────▼───────────────────────────────────────────┐
│ token_ids: [101, 1045, 2253, 2000, 3573, 1012, 102, ...]  │
│    ↓                                                        │
│ Detokenization                                              │
│    ↓                                                        │
│ Generated Text: "I went to store. Bought things."          │
│ (Hemingway-style: short, declarative sentences)            │
└─────────────────────────────────────────────────────────────┘

TRAINING FLOW
┌─────────────────────────────────────────────────────────────┐
│ Forward Pass:                                               │
│ source + style_example → model → predicted_tokens          │
│                                                             │
│ Loss Calculation:                                           │
│ CrossEntropyLoss(predicted_tokens, target_tokens)          │
│                                                             │
│ Backpropagation:                                            │
│ Updates ALL components: BERT + Style Encoder + Necks + Heads│
└─────────────────────────────────────────────────────────────┘

KEY POINTS:
• One unified PyTorch model (not separate models)
• Sequential processing: BERT → Style → Neck → Head
• Same BERT processes source and style separately
• Style vector enables zero-shot transfer to new authors
• End-to-end differentiable training
