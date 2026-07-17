#!/bin/bash
# Starts the OFFLINE sensei brain (arch 08): llama.cpp server + Qwen3-1.7B
# Q4_K_M on 127.0.0.1:8089 (OpenAI-compatible). The web server's AI proxy
# fails over to it automatically when no cloud provider answers.
# Model+binary live OUTSIDE the repo: ../.claude/llm/ (downloaded 2026-07-17).
LLM_DIR="$(dirname "$0")/../../.claude/llm"
exec "$LLM_DIR"/llama-b*/llama-server \
  -m "$LLM_DIR/qwen3-1.7b-q4km.gguf" \
  --host 127.0.0.1 --port 8089 \
  -c 4096 --reasoning-budget 0 -t $(nproc) 2>&1
