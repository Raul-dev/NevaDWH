---
workspace: dwh-engineer
title: "MQ Message Queue Service — stub"
source: curated
status: test-stub
---

# MQ (Message Queue Service) — stub для Engineer RAG

Сервис **MQ** переносит сообщения между БД (SQL Server / PostgreSQL) и очередями **RabbitMQ** или **Kafka**.

## Основные сценарии

1. **SendMsg** — выбрать сообщения из БД → опубликовать в очередь.
2. **GetMsg** — потребить из очереди → сохранить в БД.
3. **Web API** (`MQ.WebService`) — start/stop/reset, status, meta-maps, health.

## Типичные таблицы (метахранилище)

| Таблица / сущность | Назначение |
|-------------------|------------|
| `msgqueue` | Очередь сообщений в БД |
| `orders_log_buffer` | Буфер логов заказов |
| `metamap` / `metadata` | Метаданные mapping |

## API (кратко)

- `POST /v1/mq/service/start|stop|reset`
- `GET /v1/mq/service/status`, `GET /v1/mq/health`
- `GET|POST /v1/mq/meta-maps`

Legacy совместимость с NevaDWH: пути вида `/api/MetaMapsOds`, `/api/Setup/Reset`.

## Что сказать пользователю в тесте

- «MQ — транспорт между БД и RabbitMQ/Kafka; **SendMsg** / **GetMsg**; управление через MQ.WebService.»
- Статус: `GET /v1/mq/service/status`, health: `GET /v1/mq/health`.
- Детали конкретной процедуры клиента — только после индексации SQL-корпуса.
