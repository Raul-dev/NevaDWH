# Neva RAG Eval (.NET 9)

Консольный раннер для локальной проверки RAG + system prompt против **Ollama** (режим query, как в AnythingLLM).

Не требует поднятого AnythingLLM — только Ollama с моделью `llama3` / `qwen2.5`.

## Быстрый старт

```powershell
cd src\images\anything-llm

# WSL Ollama (по умолчанию) + eval portal
.\startrag.ps1

# Docker Ollama (nevaaichat-ollama) + eval
.\startrag.ps1 -Ollama docker

# Engineer + оба корпуса
.\startrag.ps1 -Corpus engineer
.\startrag.ps1 -Corpus both -Ollama wsl

# Только поднять Ollama, без тестов
.\startrag.ps1 -SkipEval

# Вручную (Ollama уже запущен)
dotnet run --project NevaRagEval -- --corpus portal
```

Ollama по умолчанию: `http://localhost:11434` (Docker compose `ollama` проброшен на хост).

## Что делает

1. Загружает `rag/{corpus}/**/*.md` и `system-prompt.txt`
2. Подставляет `NEVA_RAG_BASE_URL` (`--base-url`)
3. Делит документы на чанки, выбирает Top-K по лексике (или embeddings с `--embeddings`)
4. Шлёт в Ollama `/api/chat`: system prompt + контекст + вопрос
5. Сверяет ответ с колонкой «Ожидание» из `eval-questions.md`
6. Пишет отчёт в `eval-results/eval-{corpus}-{timestamp}.md`

## Параметры

| Параметр | По умолчанию                             |
| ---------------- | --------------------------------------------------- |
| `--corpus`     | `portal`                                          |
| `--rag-root`   | `../rag`                                          |
| `--ollama`     | `http://localhost:11434`                          |
| `--model`      | `llama3`                                          |
| `--base-url`   | `https://dwh.neva.cloudns.nz`                     |
| `--top-k`      | `4`                                               |
| `--min-pass`   | `0.6` (доля сценариев для exit 0) |

Переменные окружения: `NEVA_RAG_EVAL_ChatModel`, `NEVA_RAG_EVAL_OllamaBaseUrl`, …

# Engineer corpus (`rag/engineer/`)

Stub-корпус для **Neva DWH Engineer**: слои Landing/ODS/DWH, схемы mq/etl/staging, MQ-сервис.

Curated FAQ (как у portal): `03-`…`10-` в `_curated/`, шаблоны ответов для `eval-questions.md`.

```powershell
.\startrag.ps1 -Corpus engineer
```

Критерий smoke: ≥6/10 (цель pipeline, не точность 7B).

## Ограничения

- Упрощённый RAG (лексический поиск), не идентичен LanceDB AnythingLLM
- Авто-скоринг эвристический — смотрите отчёт глазами
- Для embeddings: `ollama pull nomic-embed-text` и флаг `--embeddings`
