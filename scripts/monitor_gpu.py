#!/usr/bin/env python3
"""Real-time GPU monitoring for TextForensics training"""

import subprocess
import time
import json
import argparse
from datetime import datetime

def get_gpu_stats():
    """Get current GPU statistics"""
    try:
        result = subprocess.run([
            "nvidia-smi", 
            "--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw",
            "--format=csv,noheader,nounits"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            stats = result.stdout.strip().split(", ")
            return {
                "name": stats[0],
                "temperature": int(stats[1]),
                "utilization": int(stats[2]),
                "memory_used": int(stats[3]),
                "memory_total": int(stats[4]),
                "power_draw": float(stats[5]),
                "timestamp": datetime.now().isoformat()
            }
    except Exception as e:
        print(f"Error getting GPU stats: {e}")
    return None

def monitor_training(interval=2, log_file=None):
    """Monitor GPU usage during training"""
    print("🖥️  GPU Monitoring for TextForensics")
    print("=" * 60)
    
    stats_history = []
    
    try:
        while True:
            stats = get_gpu_stats()
            if stats:
                # Display current stats
                print(f"\r🌡️  {stats['temperature']}°C | "
                      f"📊 GPU: {stats['utilization']}% | "
                      f"💾 VRAM: {stats['memory_used']}/{stats['memory_total']}MB | "
                      f"⚡ {stats['power_draw']}W", end="", flush=True)
                
                # Log to file if specified
                if log_file:
                    stats_history.append(stats)
                    if len(stats_history) % 30 == 0:  # Save every minute
                        with open(log_file, 'w') as f:
                            json.dump(stats_history, f, indent=2)
                
                # Alert on high temperature
                if stats['temperature'] > 80:
                    print(f"\n⚠️  High temperature: {stats['temperature']}°C")
                
                # Alert on high memory usage
                memory_percent = (stats['memory_used'] / stats['memory_total']) * 100
                if memory_percent > 90:
                    print(f"\n⚠️  High VRAM usage: {memory_percent:.1f}%")
            
            time.sleep(interval)
            
    except KeyboardInterrupt:
        print("\n\n✅ Monitoring stopped")
        if log_file and stats_history:
            with open(log_file, 'w') as f:
                json.dump(stats_history, f, indent=2)
            print(f"📊 Stats saved to: {log_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Monitor GPU usage")
    parser.add_argument("--interval", type=int, default=2, help="Update interval in seconds")
    parser.add_argument("--log", type=str, help="Log file path")
    
    args = parser.parse_args()
    monitor_training(args.interval, args.log)
