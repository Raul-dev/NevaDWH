# Ollama в WSL2 (Ubuntu-DWH) + доступ с LAN / k3s

GPU: **NVIDIA GeForce RTX 3070 8GB**. Systemd в WSL не используется — запуск через скрипты.

---

## Быстрый старт (рекомендуется)

В **PowerShell** из этой папки:

```powershell
cd .\src\images\ollama
.\start-ollama-wsl.ps1
```

Скрипт:

1. Запускает WSL `Ubuntu-DWH`
2. Стартует `ollama serve` с `OLLAMA_HOST=0.0.0.0` (файл `ollama-serve.sh`)
3. Запрашивает **Admin** и выполняет `forward_ports.ps1` (portproxy + firewall)

Проверка:

| Откуда            | URL                                                | Должно работать                  |
| ----------------------- | -------------------------------------------------- | ---------------------------------------------- |
| Windows                 | `http://localhost:11434/`                        | да                                           |
| Другой ПК / k3s | `http://192.168.0.72:11434/`                     | да (IP**Windows**, см. `ipconfig`) |
| Напрямую IP WSL | `http://192.168.x.x:11434/` из `hostname -I` | **нет** (WSL2 за NAT)               |

---

## Почему `OLLAMA_HOST=0.0.0.0` недостаточно для `192.168.0.72`

WSL2 — отдельная виртуальная сеть. Даже если Ollama слушает `0.0.0.0:11434` **внутри** Linux:

- `localhost:11434` на Windows часто работает (проброс localhost в новых WSL)
- **LAN** (`192.168.0.72`) — это интерфейс **Windows**. Нужен **portproxy**:

  `0.0.0.0:11434 (Windows) → <IP WSL>:11434`

Без `forward_ports.ps1` с других машин и из k3s (`Deployment/external-ollama.yaml`) API недоступен.

---

## Скрипты

| Файл                 | Назначение                                                      |
| ------------------------ | ------------------------------------------------------------------------- |
| `start-ollama-wsl.ps1` | WSL + Ollama + вызов port forward                                    |
| `ollama-serve.sh`      | Запуск/перезапуск`ollama serve` в WSL (без systemd) |
| `forward_ports.ps1`    | **Admin:** portproxy + firewall + проверка                  |

Параметры:

```powershell
.\start-ollama-wsl.ps1 -WslDistro Ubuntu-DWH
.\start-ollama-wsl.ps1 -SkipPortForward          # только Ollama в WSL
.\start-ollama-wsl.ps1 -ForwardOnly              # только portproxy (Ollama уже запущена)
.\forward_ports.ps1 -SkipBrowser
```

---

## Ручной запуск (без скриптов)

**PowerShell — WSL:**

```powershell
wsl -d Ubuntu-DWH
```

**Внутри Ubuntu:**

```bash
export OLLAMA_HOST=0.0.0.0
export OLLAMA_ORIGINS=*
pkill -f "ollama serve" 2>/dev/null || true
nohup ollama serve >> /tmp/ollama-serve.log 2>&1 &
curl -s http://127.0.0.1:11434/
```

**PowerShell от Администратора — проброс:**

```powershell
.\forward_ports.ps1
```

---

## WSL: базовые команды

```powershell
wsl --list --verbose
wsl -d Ubuntu-DWH
wsl --terminate Ubuntu-DWH
wsl --shutdown
```

**GPU в WSL:**

```bash
nvidia-smi
ollama list
ollama run qwen2.5-coder:7b
```

Выход из чата модели: `/exit`

---

## Интеграция с k3s / Neva AI

В `Deployment/external-ollama.yaml` в Endpoints укажите **LAN IP Windows** (например `192.168.0.72`), не IP из `hostname -I` в WSL.

Проверка с другой машины в сети:

```text
http://192.168.0.72:11434/
```

Ответ: `Ollama is running`.

Страница Neva AI проверяет `GET /nevaaiollama/` через ingress (Traefik strip-prefix → тот же Ollama).

---

## Lobe Chat (локально)

После запуска Ollama:

```powershell
docker run -p 3210:3210 --name lobe-chat `
  -e OLLAMA_PROXY_URL=http://host.docker.internal:11434 `
  -e ENABLED_MODELS=-all,ollama `
  lobehub/lobe-chat
```

---

## Устранение неполадок

**Работает localhost, не работает 192.168.0.72**

1. Запустите `.\forward_ports.ps1` **от Администратора**
2. `netsh interface portproxy show v4tov4` — должна быть строка `0.0.0.0:11434 → <wsl-ip>:11434`
3. Правило firewall `Ollama API WSL2 (11434)`
4. После `wsl --shutdown` IP WSL меняется — **перезапустите** `forward_ports.ps1`

**Ollama не стартует в WSL**

```bash
tail -50 /tmp/ollama-serve.log
ss -tlnp | grep 11434
```

**Порт занят в Windows**

```powershell
netstat -ano | findstr :11434
```

---

## OpenCode (экспериментально)

Конфиг: `wsl_opencode.sh`. Базовый URL для Ollama в WSL: `http://127.0.0.1:11434`.
