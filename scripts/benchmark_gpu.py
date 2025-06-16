#!/usr/bin/env python3
"""GPU benchmarking for TextForensics on RTX 5070 Ti"""

import torch
import time
from transformers import BertModel, BertConfig

def benchmark_gpu():
    """Benchmark GPU performance for TextForensics workloads"""
    
    if not torch.cuda.is_available():
        print("❌ CUDA not available!")
        return
    
    device = torch.device("cuda:0")
    print(f"🚀 Benchmarking on: {torch.cuda.get_device_name(0)}")
    print(f"💾 GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
    
    # Test different batch sizes and sequence lengths
    batch_sizes = [1, 4, 8, 16, 32]
    seq_lengths = [128, 256, 512, 1024]
    
    # Initialize BERT model for realistic workload
    config = BertConfig(hidden_size=768, num_hidden_layers=12, num_attention_heads=12)
    model = BertModel(config).to(device)
    model.eval()
    
    print("\n📊 Performance Benchmarks:")
    print("Batch Size | Seq Length | Forward Pass (ms) | GPU Memory (GB)")
    print("-" * 65)
    
    for batch_size in batch_sizes:
        for seq_length in seq_lengths:
            try:
                # Create random input
                input_ids = torch.randint(0, 30522, (batch_size, seq_length)).to(device)
                attention_mask = torch.ones_like(input_ids).to(device)
                
                # Warm up
                with torch.no_grad():
                    for _ in range(3):
                        _ = model(input_ids, attention_mask)
                
                torch.cuda.synchronize()
                
                # Benchmark
                start_time = time.time()
                with torch.no_grad():
                    outputs = model(input_ids, attention_mask)
                torch.cuda.synchronize()
                end_time = time.time()
                
                forward_time = (end_time - start_time) * 1000  # Convert to ms
                memory_used = torch.cuda.memory_allocated() / 1e9  # Convert to GB
                
                print(f"{batch_size:10d} | {seq_length:10d} | {forward_time:13.2f} | {memory_used:13.2f}")
                
                # Clear memory
                del outputs
                torch.cuda.empty_cache()
                
            except RuntimeError as e:
                if "out of memory" in str(e):
                    print(f"{batch_size:10d} | {seq_length:10d} | {'OOM':>13} | {'OOM':>13}")
                    torch.cuda.empty_cache()
                else:
                    raise e
    
    print(f"\n✅ Benchmark complete!")
    print(f"🎯 Recommended settings for RTX 5070 Ti:")
    print(f"   - Training batch size: 16-32")
    print(f"   - Max sequence length: 512")
    print(f"   - Mixed precision: True (BF16)")

if __name__ == "__main__":
    benchmark_gpu()
