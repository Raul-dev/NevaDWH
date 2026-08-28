#!/bin/sh
# Ollama container entrypoint: start serve, ensure init models, then wait.
#
# Neva alias scheme (важно для 1B ↔ 7B):
#   pull llama3.2:1b  → local name llama3
#   pull qwen2.5:1.5b → local name qwen2.5
# Workspace / AnythingLLM всегда зовут короткое имя (llama3 | qwen2.5).
# На внешнем GPU-Ollama лежат те же имена, но 7B+ — меняем только host (?external1).
#
# OLLAMA_INIT_MODELS: "pullTag=localName" or "tag" (space-separated).
set -eu

echo "[ollama-entrypoint] starting ollama serve"
ollama serve &
pid=$!
trap 'kill "$pid" 2>/dev/null || true' INT TERM

i=0
until ollama list >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 90 ]; then
    echo "[ollama-entrypoint] ollama did not become ready" >&2
    exit 1
  fi
  sleep 1
done
echo "[ollama-entrypoint] ollama is ready"

MODELS="${OLLAMA_INIT_MODELS:-llama3.2:1b=llama3 qwen2.5:1.5b=qwen2.5}"

for spec in $MODELS; do
  case "$spec" in
    *=*)
      src=${spec%%=*}
      name=${spec#*=}
      ;;
    *)
      src=$spec
      name=$spec
      ;;
  esac

  if [ -z "$src" ] || [ -z "$name" ]; then
    echo "[ollama-entrypoint] skip empty spec: '$spec'" >&2
    continue
  fi

  if ollama show "$name" >/dev/null 2>&1; then
    echo "[ollama-entrypoint] model present: $name"
    continue
  fi

  if [ "$src" != "$name" ] && ollama show "$src" >/dev/null 2>&1; then
    echo "[ollama-entrypoint] alias $src -> $name"
    ollama cp "$src" "$name"
    continue
  fi

  echo "[ollama-entrypoint] pulling $src"
  ollama pull "$src"
  if [ "$src" != "$name" ]; then
    echo "[ollama-entrypoint] alias $src -> $name"
    ollama cp "$src" "$name"
  fi
done

echo "[ollama-entrypoint] models ready; ollama serve pid=$pid"
wait "$pid"
