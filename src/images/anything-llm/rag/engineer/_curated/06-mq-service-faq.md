---
workspace: dwh-engineer
title: "Что делает сервис MQ"
source: curated
---

# Что делает сервис MQ?

**Шаблон ответа:** Сервис **MQ** переносит сообщения между БД (SQL Server / PostgreSQL) и **RabbitMQ** или **Kafka**:
- **SendMsg** — из БД в очередь;
- **GetMsg** — из очереди в БД.

Управление: **MQ.WebService** (start/stop/status).

Таблицы метахранилища: `msgqueue`, `orders_log_buffer`, `metamap`.
