# AnythingLLM — Dockerfile, RAG и промпты (Neva)

Эта папка **не** содержит исходников приложения. Только:

```
src/images/anything-llm/
├── Dockerfile              ← сборка образа (context = src/anythingllm/src)
├── rag/portal/             ← Portal Helper (docs, curated, prompts)
├── rag/engineer/           ← DWH Engineer stub
├── scripts/                ← export/upload RAG
├── NevaRagEval/            ← .NET 9: тест RAG + Ollama по eval-questions.md
└── README.md
```

Исходный код AnythingLLM: **`src/anythingllm/`**  
(сборка берёт `src/anythingllm/src` — frontend, server, collector, docker).

---

## Сборка и запуск

```powershell
cd .

docker compose -f docker-compose-WebAI.yml build anything-llm ollama
docker compose -f docker-compose-WebAI.yml up -d traefik ollama anything-llm

docker logs anythingllm 2>&1 | Select-String "NevaRAG"
```

Compose:

| Что | Путь |
|-----|------|
| Build context | `src/anythingllm/src` |
| Dockerfile | `src/images/anything-llm/Dockerfile` |
| `.env` / storage | `src/anythingllm/` |
| RAG mount | `src/images/anything-llm/rag` → `/rag` |

Env: `NEVA_RAG_PORTAL=/rag/portal`, `NEVA_RAG_ENGINEER=/rag/engineer`.
`NEVA_RAG_BASE_URL` (alias `RAG_BASE_URL`, default `https://dwh.neva.cloudns.nz`) —
при bootstrap все `/docs/`, `/generator/` и т.п. в корпусе и system prompt
становятся абсолютными URL; модели запрещено выдумывать чужие домены.

---

## Модели — короткие имена (обязательно)

| Workspace | chatModel | В Docker (init) | На EXTERNAL1 (GPU) |
|-----------|-----------|-----------------|---------------------|
| Portal Helper | `llama3` | `llama3.2:1b` → cp `llama3` | тот же тег `llama3` = 7B+ |
| DWH Engineer | `qwen2.5` | `qwen2.5:1.5b` → cp `qwen2.5` | тот же тег `qwen2.5` = 7B+ |

Кнопка 7B меняет **только host** (`?external1`), не имя модели.  
Подробно: `doc/Corporate_RAG_план.md` → «Модели Ollama — схема коротких имён».

`OLLAMA_INIT_MODELS=llama3.2:1b=llama3 qwen2.5:1.5b=qwen2.5`

---

## 7B / external Ollama (`?external1`)

Кнопка **7B** на `/nevaai` открывает  
`/nevaaichat/workspace/{slug}?external1`.

AnythingLLM (fork):

1. HTML/SPA ставит cookie `neva_ollama=external1`
2. Каждый API-запрос → middleware читает cookie / header / query
3. Chat идёт на `OLLAMA_BASE_PATH_EXTERNAL1` с моделью `OLLAMA_MODEL_EXTERNAL1`
4. Без `?external1` cookie сбрасывается → снова Docker 1B

Env (compose / `.env`):

```
OLLAMA_BASE_PATH=http://ollama:11434
OLLAMA_MODEL_PREF=deepseek-r1:1.5b
OLLAMA_BASE_PATH_EXTERNAL1=http://192.168.0.72:11434
OLLAMA_MODEL_EXTERNAL1=qwen2.5:7b
```

Embeddings остаются на Docker Ollama. Health 7B: `/nevaaiollama/`.

Код: `src/anythingllm/src/server/utils/nevaOllamaContext.js`

---

## Обновление RAG

1. Правки в `rag/portal/` или `rag/engineer/` → `restart anything-llm`
2. Docs портала: `node src/images/anything-llm/scripts/export-portal-rag.mjs` → restart
3. Force: `NEVA_RAG_BOOTSTRAP_FORCE=true` на один запуск

Правки кода (`src/anythingllm/src/...`) → **rebuild** образа.

---

## Локальный eval (без AnythingLLM)

```powershell
cd src/images/anything-llm
.\startrag.ps1                    # WSL + portal eval
.\startrag.ps1 -Ollama docker     # Docker nevaaichat-ollama + eval
```

См. `NevaRagEval/README.md`.

---

## Workspaces

| Workspace | URL slug |
|-----------|----------|
| Neva Portal Helper | `neva-portal-helper` |
| Neva DWH Engineer | `neva-dwh-engineer` |

- Portal: http://localhost/nevaaichat/workspace/neva-portal-helper
- Engineer: http://localhost/nevaaichat/workspace/neva-dwh-engineer

---

## Документы

- `doc/Corporate_RAG_план.md`
- `doc/AI_доступы_Profile_план.md`
