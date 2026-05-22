#!/bin/bash
# Start llama.cpp server with GPU offload (RTX 4000 Ada).
# Adjust -ngl (GPU layers) per model size.
set -e

source ../.env 2>/dev/null || true
MODEL=${CHAT_MODEL_PATH:-./models/chat.gguf}

echo "Starting llama.cpp — model: $MODEL"

./server \
  -m "$MODEL" \
  --host 0.0.0.0 \
  --port 8080 \
  -ngl 35 \
  --ctx-size 2048 \
  --threads 8
