Zero-Shot Style Transfer Architecture (6-Month Focus)
═══════════════════════════════════════════════════════════════

INPUT PROCESSING
┌─────────────────────────────────────────────────────────────┐
│ Source Text: "I went to the store to buy groceries."       │
│ Style Example: "The old man sat by the sea. He waited."    │
│ (Hemingway style - short, declarative sentences)           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                TOKENIZATION
┌─────────────────▼───────────────────────────────────────────┐
│ BERT Tokenizer (bert-base-uncased)                         │
│ Source IDs: [101, 1045, 2253, 2000, ...]                  │
│ Style IDs: [101, 1996, 2214, 2158, ...]                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
═══════════════════════════════════════════════════════════════
                SHARED BACKBONE
═══════════════════════════════════════════════════════════════
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                BERT-BASE-UNCASED                            │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 12 Transformer Layers                                   │ │
│ │ 768 hidden size, 12 attention heads                    │ │
│ │ Input → Contextual Embeddings (768-dim)                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Outputs:                                                    │
│ - Source Embeddings: 768-dim per token                     │
│ - Style Embeddings: 768-dim per token                      │
│ - Pooled Outputs: 768-dim sentence representations         │
└─────────────────┬───────────────────────────────────────────┘
                  │
═══════════════════════════════════════════════════════════════
                STYLE ENCODER
═══════════════════════════════════════════════════════════════
                  │
┌─────────────────▼───────────────────────────────────────────┐
│              DUAL STYLE ENCODER                             │
│                                                             │
│ Source Processing:                                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Source Pooled (768) → Linear(768→768) → GELU → LayerNorm│ │
│ │ Output: Source Style Vector (768-dim)                   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Target Style Processing:                                    │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Style Pooled (768) → Linear(768→768) → GELU → LayerNorm │ │
│ │ Output: Target Style Vector (768-dim)                   │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
═══════════════════════════════════════════════════════════════
               GENERATION NECK
═══════════════════════════════════════════════════════════════
                  │
┌─────────────────▼───────────────────────────────────────────┐
│            CONTENT/STYLE DISENTANGLEMENT                    │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                CONTENT ENCODER                          │ │
│ │                                                         │ │
│ │ Input: Source Style Vector (768-dim)                   │ │
│ │ ↓                                                       │ │
│ │ Linear: 768 → 512 (content projection)                 │ │
│ │ ReLU activation                                         │ │
│ │ Dropout(0.1)                                           │ │
│ │ ↓                                                       │ │
│ │ Output: Content Features (512-dim)                     │ │
│ │ [Semantic meaning, topic, facts - style-agnostic]      │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                STYLE EXTRACTOR                          │ │
│ │                                                         │ │
│ │ Input: Target Style Vector (768-dim)                   │ │
│ │ ↓                                                       │ │
│ │ Linear: 768 → 256 (style projection)                   │ │
│ │ Tanh activation (bounded style space)                  │ │
│ │ ↓                                                       │ │
│ │ Output: Style Features (256-dim)                       │ │
│ │ [Sentence length, complexity, word choice patterns]    │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │              STYLE CONDITIONING                         │ │
│ │                                                         │ │
│ │ Content Features (512) + Style Features (256)          │ │
│ │ ↓                                                       │ │
│ │ Concatenation → 768-dim                                │ │
│ │ Linear: 768 → 768                                      │ │
│ │ LayerNorm                                              │ │
│ │ ↓                                                       │ │
│ │ Output: Conditioned Features (768-dim)                 │ │
│ │ [Content semantics + Target style guidance]            │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────┬───────────────────────────────────────────┘
                  │
═══════════════════════════════════════════════════════════════
              STYLE TRANSFER HEAD
═══════════════════════════════════════════════════════════════
                  │
┌─────────────────▼───────────────────────────────────────────┐
│               TEXT GENERATION HEAD                          │
│                                                             │
│ Input: Conditioned Features (768-dim)                      │
│ ↓                                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │              DECODER LAYERS                             │ │
│ │                                                         │ │
│ │ Layer 1: Self-Attention + Cross-Attention              │ │
│ │          (attends to source tokens + style)            │ │
│ │ Layer 2: Feed-Forward (768→3072→768)                   │ │
│ │ Layer 3: [Repeat 2-3 more layers]                      │ │
│ │                                                         │ │
│ │ Output: Contextualized Features (768-dim)              │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ↓                                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │             VOCABULARY PROJECTION                       │ │
│ │                                                         │ │
│ │ Linear: 768 → 30522 (BERT vocab size)                  │ │
│ │ Softmax → Token Probabilities                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ↓                                                           │
│ Output Tokens: [101, 1045, 2253, 2000, 1996, ...]         │
└─────────────────┬───────────────────────────────────────────┘
                  │
═══════════════════════════════════════════════════════════════
                    OUTPUT
═══════════════════════════════════════════════════════════════
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                DETOKENIZATION                               │
│                                                             │
│ Generated Text: "I went to store. Bought groceries.        │
│                 Came home."                                 │
│                                                             │
│ Style Applied: Hemingway-like short, declarative sentences │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
                 TRAINING STRATEGY
═══════════════════════════════════════════════════════════════

TRAINING DATA:
┌─────────────────────────────────────────────────────────────┐
│ Triplets: (Source_Text, Style_Example, Target_Text)        │
│                                                             │
│ Example:                                                    │
│ Source: "I went to the store to buy groceries."           │
│ Style: "The old man sat by the sea. He waited."           │
│ Target: "I went to store. Bought groceries."              │
└─────────────────────────────────────────────────────────────┘

LOSS FUNCTION:
┌─────────────────────────────────────────────────────────────┐
│ L_transfer = CrossEntropyLoss(predicted_tokens, target)     │
│                                                             │
│ Optional auxiliary losses:                                  │
│ - L_content_preservation (semantic similarity)             │
│ - L_style_consistency (style matching)                     │
│                                                             │
│ Total: L = L_transfer + α*L_content + β*L_style            │
└─────────────────────────────────────────────────────────────┘

ZERO-SHOT INFERENCE:
┌─────────────────────────────────────────────────────────────┐
│ 1. Extract style from ANY example text                     │
│ 2. Apply to ANY source text                                │
│ 3. No retraining required                                  │
│                                                             │
│ Key: Style vector generalizes across authors/domains       │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
                 IMPLEMENTATION PRIORITY
═══════════════════════════════════════════════════════════════

Phase 1 (Months 1-2): Core Architecture
✓ BERT backbone + Style encoder
✓ Generation neck (content/style separation)
✓ Basic transfer head implementation
✓ Training loop with synthetic data

Phase 2 (Months 3-4): Zero-Shot Capability
✓ Style vector extraction and conditioning
✓ Evaluation on Spooky Authors dataset
✓ Human evaluation of transfer quality
✓ Comparison with baselines

Phase 3 (Months 5-6): Extension & Thesis
✓ Add 1-2 additional heads (classification/similarity)
✓ Comprehensive evaluation
✓ Thesis writing and paper preparation

KEY SUCCESS METRICS:
- Style transfer quality (human evaluation >3.5/5.0)
- Content preservation (BLEU score >0.6)
- Zero-shot generalization (new authors without retraining)
