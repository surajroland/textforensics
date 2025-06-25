# QuillForge Multi-Task Neural Text Forensics Architecture

## Complete Architecture Diagram (ASCII)

```
                    ┌─────────────────────────────────────┐
                    │            INPUT TEXT               │
                    │      "I am going to the store"      │
                    └─────────────┬───────────────────────┘
                                  │
                    ┌─────────────▼───────────────────────┐
                    │         SHARED BACKBONE             │
                    │                                     │
                    │  ┌─────────────┐ ┌─────────────┐    │
                    │  │   BERT-BASE │ │   GPT-2     │    │
                    │  │  (Encoder)  │ │ (Decoder)   │    │
                    │  │   12 layers │ │  12 layers  │    │
                    │  │   768 dim   │ │   768 dim   │    │
                    │  └─────────────┘ └─────────────┘    │
                    │                                     │
                    │     Universal Text Understanding    │
                    │        768-dim embeddings           │
                    └─────────────┬───────────────────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
            ▼                     ▼                     ▼
  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
  │ CLASSIFICATION  │   │   GENERATION    │   │    ANALYSIS     │
  │     NECK        │   │      NECK       │   │     NECK        │
  └─────────────────┘   └─────────────────┘   └─────────────────┘
            │                     │                     │
            ▼                     ▼                     ▼
    ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
    │   Features    │     │ Content/Style │     │  Temporal +   │
    │ Extraction +  │     │ Disentangle + │     │ Multi-scale   │
    │   Pooling     │     │ Conditioning  │     │  Features     │
    └───────────────┘     └───────────────┘     └───────────────┘
            │                     │                     │
            ▼                     ▼                     ▼
    ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
    │   3 HEADS     │     │   3 HEADS     │     │   3 HEADS     │
    └───────────────┘     └───────────────┘     └───────────────┘
```

## Detailed Head-by-Head Expansion

### GENERATION NECK + HEADS (Primary Focus)

```
┌─────────────────────────────────────────────────┐
│                     GENERATION NECK             │
│                                                 │
│  Input: 768-dim backbone features               │
│                         │                       │
│  ┌─────────────────────▼─────────────────────┐  │
│  │         CONTENT/STYLE SEPARATOR           │  │
│  │                                           │  │
│  │  ┌─────────────┐     ┌─────────────┐      │  │
│  │  │   Content   │     │    Style    │      │  │
│  │  │   Encoder   │     │   Encoder   │      │  │
│  │  │             │     │             │      │  │
│  │  │ 768→512 dim │     │ 768→256 dim │      │  │
│  │  │   (what)    │     │   (how)     │      │  │
│  │  └─────────────┘     └─────────────┘      │  │
│  └─────────────────────┬─────────────────────┘  │
│                        │                        │
│  ┌─────────────────────▼─────────────────────┐  │
│  │        STYLE CONDITIONING MODULE          │  │
│  │                                           │  │
│  │  Content(512) + Target_Style(256) →       │  │
│  │         Conditioned_Features(768)         │  │
│  └─────────────────────┬─────────────────────┘  │
│                        │                        │
│                        ▼                        │
└─────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│STYLE        │  │CROSS-GENRE  │  │ZERO-SHOT    │
│TRANSFER     │  │TRANSFER     │  │MIMICRY      │
│HEAD         │  │HEAD         │  │HEAD         │
│             │  │             │  │             │
│768→vocab    │  │768→vocab    │  │768→vocab    │
│Linear+      │  │Linear+      │  │Meta-Learning│
│Softmax      │  │Domain Adapt │  │Few-shot     │
│             │  │             │  │Adaptation   │
│Output:      │  │Output:      │  │Output:      │
│"I'm going   │  │Domain-aware │  │Style from   │
│to store"    │  │transfer     │  │1 example    │
└─────────────┘  └─────────────┘  └─────────────┘
```

### CLASSIFICATION NECK + HEADS

```
┌─────────────────────────────────────────────────┐
│                  CLASSIFICATION NECK            │
│                                                 │
│        Input: 768-dim backbone features         │
│                        │                        │
│  ┌─────────────────────▼─────────────────────┐  │
│  │       FEATURE EXTRACTION MODULE           |  │
│  │                                           |  │
│  │  ┌─────────────┐     ┌─────────────┐      |  │
│  │  │  Attention  │     │   Global    │      |  │
│  │  │   Pooling   │     │   Average   │      |  │
│  │  │             │     │   Pooling   │      |  │
│  │  │ 768→384 dim │     │ 768→384 dim │      |  │
│  │  └─────────────┘     └─────────────┘      |  │
│  │           │                   │           |  │
│  │           └─────────┬─────────┘           |  │
│  │                     │                     |  │
│  │  ┌─────────────────▼─────────────────┐    |  │
│  │  │     FEATURE FUSION (768 dim)      │    |  │
│  │  └─────────────────┬─────────────────┘    |  │
│  └─────────────────────┬─────────────────────┘  │
│                        │                        │
│  ┌─────────────────────▼─────────────────────┐  │
│  │         CLASSIFICATION FEATURES           │  │
│  │              (768 dim)                    │  │
│  └─────────────────────┬─────────────────────┘  │
└─────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│STYLE        │  │ANOMALY      │  │GENRE        │
│CLASSIFICATION│ │DETECTION    │  │CLASSIFICATION│
│HEAD         │  │HEAD         │  │HEAD         │
│             │  │             │  │             │
│768→512→N    │  │768→512→1    │  │768→256→M    │
│(N authors)  │  │(binary)     │  │(M genres)   │
│             │  │             │  │             │
│Dropout(0.3) │  │Dropout(0.5) │  │Dropout(0.2) │
│ReLU + Linear│  │Sigmoid      │  │ReLU + Linear│
│Softmax      │  │             │  │Softmax      │
│             │  │             │  │             │
│Output:      │  │Output:      │  │Output:      │
│Author_ID    │  │Plagiarism   │  │Genre_Type   │
│Probability  │  │Score 0-1    │  │Probability  │
└─────────────┘  └─────────────┘  └─────────────┘
```

### ANALYSIS NECK + HEADS

```
┌─────────────────────────────────────────────────┐
│                     ANALYSIS NECK               │
│                                                 │
│         Input: 768-dim backbone features        │
│                         │                       │
│  ┌─────────────────────▼─────────────────────┐  |
│  │       TEMPORAL SEQUENCE PROCESSOR         |  |
│  │                                           |  |
│  │  ┌─────────────┐     ┌─────────────┐      |  |
│  │  │    LSTM     │     │ Positional  │      |  |
│  │  │ (bi-direct) │     │  Encoding   │      |  |
│  │  │             │     │             │      |  |
│  │  │ 768→512 dim │     │ 768→256 dim │      |  |
│  │  └─────────────┘     └─────────────┘      |  |
│  │           │                   │           |  |
│  │           └─────────┬─────────┘           |  |
│  │                     │                     |  |
│  │  ┌─────────────────▼─────────────────┐    |  |
│  │  │    MULTI-SCALE AGGREGATION        │    |  |
│  │  │   (Word→Sentence→Document)        │    |  |
│  │  └─────────────────┬─────────────────┘    |  |
│  └─────────────────────┬─────────────────────┘  |
│                        │                        |
│  ┌─────────────────────▼─────────────────────┐  |
│  │        ANALYSIS FEATURES (768 dim)        │  |
│  └─────────────────────┬─────────────────────┘  |
└─────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│STYLE        │  │CONSISTENCY  │  │MULTI-SCALE  │
│SIMILARITY   │  │TRACKING     │  │ANALYSIS     │
│HEAD         │  │HEAD         │  │HEAD         │
│             │  │             │  │             │
│768→512→256  │  │768→256→128  │  │768→{Word,   │
│Cosine Sim   │  │Change Detect│  │Sent,Doc}    │
│             │  │             │  │Features     │
│Embedding    │  │LSTM→Dense   │  │             │
│Space        │  │             │  │Hierarchical │
│             │  │Output:      │  │Attention    │
│Output:      │  │Consistency  │  │             │
│Similarity   │  │Score &      │  │Output:      │
│Matrix       │  │Change Points│  │Multi-level  │
│(0-1 range)  │  │             │  │Style Vector │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Advanced Heads (Future Extension)

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│STYLE        │  │ADVERSARIAL  │  │STYLE        │
│INTERPOLATION│  │ROBUSTNESS   │  │EXPLANATION  │
│HEAD         │  │HEAD         │  │HEAD         │
│             │  │             │  │             │
│768→512      │  │768→256      │  │768→512      │
│Convex Combo │  │GAN Training │  │Attention    │
│in Emb Space │  │             │  │Weights      │
│             │  │Discriminator│  │             │
│Multi-author │  │+ Adversarial│  │Human-Read   │
│Blending     │  │Loss         │  │Analysis     │
│             │  │             │  │             │
│Output:      │  │Output:      │  │Output:      │
│Blended      │  │Obfuscation  │  │Style        │
│Style Text   │  │Detection    │  │Explanation  │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Key Architecture Features

### Shared Learning Benefits
- **Cross-task Knowledge**: Style classification improves generation quality
- **Efficient Training**: Shared backbone reduces parameter count by 60%
- **Consistent Representations**: Same style understanding across all tasks

### Modular Design
- **Independent Heads**: Can train/evaluate individual capabilities
- **Scalable**: Add new heads without architectural changes
- **Task-Specific**: Each head optimized for its specific objective

### Zero-Shot Implementation Focus
The **Generation Neck → Style Transfer Head** path implements true zero-shot capability through:
1. **Content/Style Disentanglement** in the neck
2. **Style Conditioning** mechanism
3. **Target Style Injection** without retraining
