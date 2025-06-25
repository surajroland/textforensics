#!/usr/bin/env python3
"""TextForensics CLI entry point"""

import argparse
import sys
from pathlib import Path

# Add src to path for development
sys.path.insert(0, str(Path(__file__).parent.parent.parent))


def main() -> None:
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="TextForensics: Neural Text Forensics Platform"
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Train command
    train_parser = subparsers.add_parser("train", help="Train models")
    train_parser.add_argument(
        "--config", type=str, default="config.yaml", help="Config file"
    )

    # Evaluate command
    eval_parser = subparsers.add_parser("evaluate", help="Evaluate models")
    eval_parser.add_argument("--model-path", type=str, required=True, help="Model path")

    # API command
    api_parser = subparsers.add_parser("api", help="Start API server")
    api_parser.add_argument("--port", type=int, default=8000, help="Port number")

    args = parser.parse_args()

    if args.command == "train":
        print(f"🚀 Starting training with config: {args.config}")
        # Would call train() with Hydra

    elif args.command == "evaluate":
        print(f"🔍 Evaluating model: {args.model_path}")
        # Would call evaluation pipeline

    elif args.command == "api":
        print(f"🌐 Starting API server on port {args.port}")
        import uvicorn

        from textforensics.api import app

        uvicorn.run(app, host="0.0.0.0", port=args.port)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
