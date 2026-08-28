#!/usr/bin/env bash
# Start Ollama in WSL without systemd (listen on all interfaces inside WSL).
set -euo pipefail

export OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
export OLLAMA_ORIGINS="${OLLAMA_ORIGINS:-*}"

LOG_FILE="${OLLAMA_LOG:-/tmp/ollama-serve.log}"
PID_FILE="${OLLAMA_PID_FILE:-/tmp/ollama-serve.pid}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama not found in PATH" >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "Stopping ollama serve (pid $old_pid)..."
    kill "$old_pid" 2>/dev/null || true
    sleep 1
  fi
fi
pkill -f "ollama serve" 2>/dev/null || true
sleep 1

echo "OLLAMA_HOST=$OLLAMA_HOST"
nohup ollama serve >>"$LOG_FILE" 2>&1 &
echo $! >"$PID_FILE"

for _ in $(seq 1 30); do
  if curl -sf "http://127.0.0.1:11434/" >/dev/null 2>&1; then
    echo "Ollama OK: http://127.0.0.1:11434/ (log: $LOG_FILE, pid: $(cat "$PID_FILE"))"
    exit 0
  fi
  sleep 1
done

echo "Ollama did not respond within 30s. Last log lines:" >&2
tail -n 20 "$LOG_FILE" >&2 || true
exit 1
