TextForensics: Complete Multi-Task Neural Architecture
═══════════════════════════════════════════════════════════════

INPUT LAYER
┌─────────────────────────────────────────────────────────────┐
│                    RAW TEXT INPUT                           │
│  "The old man sat by the sea, waiting for something..."     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                 TOKENIZATION
┌─────────────────────▼───────────────────────────────────────┐
│               BERT TOKENIZER                                │
│ Input IDs: [101, 1996, 2214, 2158, 2938, ...]             │
│ Attention Mask: [1, 1, 1, 1, 1, ...]                      │
│ Token Type IDs: [0, 0, 0, 0, 0, ...]                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
═══════════════════════════════════════════════════════════════
                 SHARED BACKBONE
═══════════════════════════════════════════════════════════════
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 BERT-BASE-UNCASED                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              EMBEDDING LAYER                        │    │
│  │  - Token Embeddings (30522 vocab)                  │    │
│  │  - Position Embeddings (512 max)                   │    │
│  │  - Segment Embeddings                              │    │
│  │  → 768-dim embeddings                              │    │
│  └─────────────────┬───────────────────────────────────┘    │
│                    │                                        │
│  ┌─────────────────▼───────────────────────────────────┐    │
│  │           TRANSFORMER LAYERS (12x)                  │    │
│  │                                                     │    │
│  │  Layer 1:  Multi-Head Attention (12 heads)         │    │
│  │           + Feed Forward (768→3072→768)             │    │
│  │           + Layer Norm + Residual                   │    │
│  │  Layer 2:  [Same structure]                         │    │
│  │  ...                                               │    │
│  │  Layer 12: [Same structure]                        │    │
│  │                                                     │    │
│  │  Output: 768-dim contextual embeddings             │    │
│  └─────────────────┬───────────────────────────────────┘    │
│                    │                                        │
│  ┌─────────────────▼───────────────────────────────────┐    │
│  │              POOLING LAYER                          │    │
│  │  - CLS Token: [CLS] representation                 │    │
│  │  - Last Hidden State: All token representations    │    │
│  │  - Pooler Output: Tanh activation on CLS          │    │
│  └─────────────────┬───────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────┘
                      │
═══════════════════════════════════════════════════════════════
                 STYLE ENCODER
═══════════════════════════════════════════════════════════════
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                  STYLE ENCODER                              │
│                                                             │
│  Input: Pooler Output (768-dim)                            │
│         ↓                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Linear: 768 → 768                                 │    │
│  │  GELU Activation                                    │    │
│  │  LayerNorm                                          │    │
│  └─────────────────┬───────────────────────────────────┘    │
│                    ↓                                        │
│  Output: Style Embeddings (768-dim)                        │
│          Universal style representation                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
         ▼            ▼            ▼
═══════════════════════════════════════════════════════════════
              TASK-SPECIFIC NECKS
═══════════════════════════════════════════════════════════════

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│CLASSIFICATION│  │  GENERATION  │  │   ANALYSIS   │
│    NECK      │  │     NECK     │  │     NECK     │
└──────────────┘  └──────────────┘  └──────────────┘

CLASSIFICATION NECK:
┌─────────────────────────────────────────────────────────────┐
│  Input: Style Embeddings (768-dim)                         │
│         ↓                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Attention Pooling: 768→384                        │    │
│  │  Global Average Pooling: 768→384                   │    │
│  │  Concatenation: 384+384=768                        │    │
│  │  Feature Fusion + Dropout(0.3)                     │    │
│  └─────────────────┬───────────────────────────────────┘    │
│                    ↓                                        │
│  Output: Classification Features (768-dim)                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   STYLE     │ │   ANOMALY   │ │    GENRE    │
│CLASSIFICATION│ │  DETECTION  │ │CLASSIFICATION│
│    HEAD     │ │    HEAD     │ │    HEAD     │
│             │ │             │ │             │
│768→512→256  │ │768→512→128  │ │768→256→128  │
│→N_authors   │ │→1 (binary)  │ │→M_genres    │
│ReLU+Dropout │ │ReLU+Dropout │ │ReLU+Dropout │
│Softmax      │ │Sigmoid      │ │Softmax      │
└─────────────┘ └─────────────┘ └─────────────┘

GENERATION NECK:
┌─────────────────────────────────────────────────────────────┐
│  Input: Style Embeddings (768-dim)                         │
│         ↓                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │          CONTENT/STYLE SEPARATOR                    │    │
│  │                                                     │    │
│  │  Content Encoder: 768→512 (semantic meaning)       │    │
│  │  Style Encoder: 768→256 (stylistic patterns)       │    │
│  │                                                     │    │
│  │  Style Conditioning Module:                         │    │
│  │  Content(512) + Target_Style(256) → 768            │    │
│  └─────────────────┬───────────────────────────────────┘    │
│                    ↓                                        │
│  Output: Conditioned Features (768-dim)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   STYLE     │ │CROSS-GENRE  │ │ ZERO-SHOT   │
│  TRANSFER   │ │  TRANSFER   │ │  MIMICRY    │
│    HEAD     │ │    HEAD     │ │    HEAD     │
│             │ │             │ │             │
│768→30522    │ │768→30522    │ │768→30522    │
│(vocab_size) │ │+Domain      │ │+Meta-       │
│Linear+      │ │Adaptation   │ │Learning     │
│Softmax      │ │             │ │Few-shot     │
└─────────────┘ └─────────────┘ └─────────────┘

ANALYSIS NECK:
┌─────────────────────────────────────────────────────────────┐
│  Input: Style Embeddings (768-dim)                         │
│         ↓                                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │        TEMPORAL SEQUENCE PROCESSOR                  │    │
│  │                                                     │    │
│  │  BiLSTM: 768→512 (bidirectional)                   │    │
│  │  Positional Encoding: 768→256                      │    │
│  │  Multi-scale Aggregation:                          │    │
│  │    Word→Sentence→Document hierarchy                │    │
│  └─────────────────┬───────────────────────────────────┘    │
│                    ↓                                        │
│  Output: Analysis Features (768-dim)                       │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│   STYLE     │ │CONSISTENCY  │ │MULTI-SCALE  │
│ SIMILARITY  │ │  TRACKING   │ │  ANALYSIS   │
│    HEAD     │ │    HEAD     │ │    HEAD     │
│             │ │             │ │             │
│768→512→256  │ │768→256→128  │ │768→Word     │
│Embedding    │ │LSTM+Dense   │ │→Sentence    │
│Space        │ │Change       │ │→Document    │
│Cosine Sim   │ │Detection    │ │Features     │
└─────────────┘ └─────────────┘ └─────────────┘

═══════════════════════════════════════════════════════════════
                    OUTPUT LAYER
═══════════════════════════════════════════════════════════════

TASK OUTPUTS:
┌─────────────────────────────────────────────────────────────┐
│  Style Classification: [0.8 Hemingway, 0.15 Poe, 0.05 MWS] │
│  Style Transfer: "The man sat by sea. He waited."          │
│  Anomaly Detection: 0.23 (low plagiarism probability)       │
│  Similarity Score: 0.87 (high style similarity)            │
│  Consistency: [0.9, 0.8, 0.3, 0.7] (drop at position 3)   │
│  Multi-scale: {word: [...], sentence: [...], doc: [...]}   │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
                   TRAINING STRATEGY
═══════════════════════════════════════════════════════════════

MULTI-TASK LOSS:
L_total = w1*L_classification + w2*L_transfer + w3*L_anomaly + w4*L_similarity

Where:
- L_classification = CrossEntropyLoss
- L_transfer = CrossEntropyLoss (next token prediction)
- L_anomaly = BCEWithLogitsLoss
- L_similarity = MSELoss

TRAINING PHASES:
1. Backbone pre-training (optional, use pretrained BERT)
2. Multi-task joint training with task weights
3. Fine-tuning individual heads if needed

OPTIMIZATION:
- AdamW optimizer with cosine annealing
- Mixed precision (BF16) for RTX 5070 Ti
- Gradient accumulation for effective batch size
- Early stopping on validation loss

═══════════════════════════════════════════════════════════════
                   KEY FEATURES
═══════════════════════════════════════════════════════════════

✓ Shared Representations: All tasks benefit from common backbone
✓ Task-Specific Processing: Necks group similar tasks efficiently
✓ Modular Design: Add/remove heads without architecture changes
✓ Zero-Shot Capability: Style transfer without retraining
✓ Multi-Scale Analysis: Word→Sentence→Document features
✓ Production Ready: GPU optimized, Docker deployment
✓ Research Extensible: 12 planned task heads, currently 9 implemented
