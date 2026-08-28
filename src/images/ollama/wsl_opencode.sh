# 1. Создаем нужную директорию для конфигурации OpenCode в Linux
mkdir -p ~/.config/opencode/

# 2. Переходим в созданную папку
cd ~/.config/opencode/

# 3. Создаем файл конфигурации config.json с вашими настройками Ollama
cat << 'EOF' > config.json
{
  "providers": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (Local GPU)",
      "options": {
        "baseURL": "http://127.0.0.1:11434"
      },
      "models": {
        "qwen2.5:7b": {
          "name": "Qwen 2.5 7B"
        },
        "qwen2.5-coder:7b": {
          "name": "Qwen 2.5-coder 7B"
        },
        "deepseek-r1:8b": {
          "name": "DeepSeek R1 8B"
        }
      }
    }
  }
}
EOF


# 1. Переходим в папку вашего Node.js проекта
cd /mnt/f/Work/GitLab/gitlab26.neva.loc/shop/publicdwh_nodejs

# 2. Создаем файл opencode.json внутри папки проекта
cat << 'EOF' > opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "project": {
    "root": "/mnt/f/Work/GitLab/gitlab26.neva.loc/shop/publicdwh_nodejs"
  }
}
EOF

