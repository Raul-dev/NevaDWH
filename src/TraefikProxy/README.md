# BOProxy

Traefik v3.0 reverse proxy для маршрутизации HTTP/HTTPS трафика в Docker-среде.

---

## Быстрый старт

```powershell
# Создать сеть (если не существует)
docker network create proxy

# Запустить
docker-compose up -d

# Проверить статус
docker-compose ps
```

---

## Туннель на ya.ru

Трафик на порту **8500** проксируется на **https://ya.ru**.

### Тестирование

**PowerShell:**
```powershell
curl.exe http://localhost:8500
```

**Bash/curl:**
```bash
curl http://localhost:8500
```

Ожидаемый ответ: HTML-страница Яндекса.

---

## Ports

| Port  | Назначение                        |
|-------|-----------------------------------|
| 80    | HTTP → HTTPS redirect             |
| 443   | HTTPS                             |
| 8080  | Traefik Dashboard                 |
| 8500  | Туннель → ya.ru                   |

---

## Dashboard

Traefik Dashboard доступен по адресу: http://traefik.localhost:8080

---

## Команды управления

```powershell
# Логи
docker-compose logs -f

# Остановить
docker-compose down

# Перезапустить
docker-compose restart
```

---

## Конфигурация

- `data/traefik.yml` — основной конфиг Traefik
- `data/acme.json` — TLS-сертификаты Let's Encrypt
- `data/configurations/` — дополнительные роутеры и middleware

---

## Важно

`acme.json` должен иметь права `600`:

```powershell
icacls data\acme.json /inheritance:r /grant:r "$env:USERNAME:R"
```
