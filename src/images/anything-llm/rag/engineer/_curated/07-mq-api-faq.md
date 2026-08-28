---
workspace: dwh-engineer
title: "API статуса MQ"
source: curated
---

# Где API статуса MQ?

**Шаблон ответа:**
- `GET /v1/mq/service/status` — статус сервиса;
- `GET /v1/mq/health` — health check (live/ready).

Также: `POST /v1/mq/service/start|stop|reset`, meta-maps: `/v1/mq/meta-maps`.
