# NevaDWH

Результат генерации DWH из XML/JSON-метаданных 1С (выгрузка `1cv8.exe /DumpConfigToFiles`, Бит.Адаптер и др.).  
В репозитории две готовые версии стенда:

| Папка | СУБД ODS / DWH / Landing | Compose |
|-------|--------------------------|---------|
| [`dbpsql/`](./dbpsql) | **PostgreSQL** в Docker (`client-postgresdb17`) | полный стек в контейнерах |
| [`dbmssql/`](./dbmssql) | **MS SQL Server** на хосте | Airflow / Rabbit / MQ / UI в Docker |

Цель генератора — при изменении структуры 1С автоматически перестраивать схемы ODS/DWH и ETL (Airflow), добавляя новые поля в конечные таблицы.

![overview](./doc/forweb.png)

---

## Стек стенда

| Сервис | Адрес | Учётка |
|--------|-------|--------|
| Панель NevaDWH | http://localhost:8100 | первый пользователь — через UI |
| Airflow 3 UI / API | http://localhost:8080 | **admin / admin** |
| RabbitMQ Management | http://localhost:15672 | **admin / admin** |
| MQ WebService | http://localhost:8090/v1/mq/swagger | — |
| Landing WebService | http://localhost:8092/v1/landing/swagger | — |
| Traefik (опц.) | http://localhost/ | — |

**dbpsql (Postgres):** ODS `newadwh_ods`, DWH `newadwh_dwh`, Landing `newadwh_landing`  
(хост с машины: `localhost:54321`, user/password `postgres` / `postgres`).

**dbmssql:** ODS/DWH/Landing на локальном SQL Server (`NevaDWH-DEMO_*`, учётки из `dbmssql/.env`).

Приложения MQ / Landing / Generator / Admin в этом репозитории берутся с Docker Hub (`raulamailru/nevadwh-*`). Airflow и Rabbit собираются из `dbpsql/images` / `dbmssql/images`.

```mermaid
flowchart LR
  RMQ[RabbitMQ]
  MQ[mq.webservice]
  ODS[(ODS odins / mq)]
  AF[Airflow dwh_etl_start]
  STG[(DWH staging)]
  TGT[(DWH target)]

  RMQ --> MQ --> ODS
  ODS --> AF --> STG --> TGT
```

**Поток данных**

1. Сообщения из `mq.msgqueue` / `mq.MessageQueue` уходят в Rabbit (`send-unresolved-msg`).
2. **MQ** пишет в ODS (`odins.*`).
3. **Airflow** `dwh_etl_start` → `dwh_etl_Star_Launcher` → DIM/FACT publish в DWH **staging**, затем **target**.

---

## Prerequisites

- Windows 10/11, PowerShell 5.1+ (рекомендуется 7.x)
- [Docker Desktop](https://www.docker.com/)
- Для **dbpsql**: достаточно Docker
- Для **dbmssql**: SQL Server 2019/2022 на хосте, Visual Studio / MSBuild + SqlPackage, модуль `VSSetup`:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine
Install-Module VSSetup -Scope AllUsers
```

Первый запуск `start.ps1` — **от администратора** (SMB share `Upload` для MSSQL XML-адаптера).

---

## Быстрый старт

### PostgreSQL (`dbpsql`)

```powershell
cd .\dbpsql
docker compose build
.\start.ps1
```

Обновление без полного пересоздания:

```powershell
.\start.ps1 -IsUpdate
```

Только пересборка init SQL для `docker-entrypoint-initdb.d` (без Docker):

```powershell
.\start.ps1 -ScriptsOnly
```

После смены major Airflow — сброс metadata volume:

```powershell
docker compose down --volumes
docker compose up airflow-init
docker compose up -d
```

### MS SQL (`dbmssql`)

```powershell
cd .\dbmssql
docker compose build
.\start.ps1          # dacpac deploy + compose
.\start.ps1 -IsUpdate
```

---

## Автотесты пайплайна (`db-tests.ps1`)

В корне репозитория:

| Файл | Назначение |
|------|------------|
| [`db-tests.ps1`](./db-tests.ps1) | подъём compose + General pipeline |
| [`db-tests.engines.ps1`](./db-tests.engines.ps1) | SQL/хелперы mssql и psql (UTF-8 BOM) |

Отчёты: `.\TestReport\` (`latest-db-NevaDWH-dbpsql.md` и т.п.).

### Что проверяет `-General` (по умолчанию)

1. **Compose** — `up` стенда, health MQ и Airflow (при переключении `dbpsql` ↔ `dbmssql` оба проекта снимаются через `compose down`, тома сохраняются).
2. **Phase 1** — `POST /v1/mq/service/send-unresolved-msg` → ожидание свежих строк в `odins` (DIM_Клиенты / Товары / FACT_Продажи; Валюты в seed может быть 0).
3. **Phase 2** — trigger DAG `dwh_etl_start`, ожидание `success`.
4. **Phase 3** — в DWH есть строки в `staging` и `target`.

### Команды

```powershell
# из корня репозитория
.\db-tests.ps1 dbpsql              # полный прогон Postgres
.\db-tests.ps1 dbpsql -Build       # с пересборкой образов
.\db-tests.ps1 dbpsql -SkipCompose # стенд уже поднят
.\db-tests.ps1 dbpsql -ClearData   # truncate odins перед Phase 1

.\db-tests.ps1 dbmssql -Build
.\db-tests.ps1 dbmssql -SkipCompose
```

### Ручной сценарий (UI) — то же, что делает тест

1. Панель http://localhost:8100 → ODS Service: включить обработку Rabbit, Reset MQ, **Send unresolved messages**.
2. Airflow http://localhost:8080 (**admin/admin**) → запустить DAG **`dwh_etl_start`**.
3. Проверить ODS `odins.*` и DWH `staging` / `target`.

---

## Полезные ссылки в стенде

| | |
|--|--|
| Admin | http://localhost:8100 |
| Airflow | http://localhost:8080 |
| RabbitMQ | http://localhost:15672 |
| MQ Swagger | http://localhost:8090/v1/mq/swagger |
| Landing Swagger | http://localhost:8092/v1/landing/swagger |

![Admin](./doc/Admin.png)

![Airflow](./doc/airflow.png)

![DWH](./doc/dwh.png)

![1C](./doc/odinc.png)

![Proc log](./doc/log.png)

### MSSQL: audit / XML

В MSSQL есть лог процедур (через Linked Server `LinkSRVLogLanding`) в `[nevadwh_landing].[audit].[LogProcedures]` и загрузка XML с share **UPLOAD** (настраивается в `start.ps1`). Тестовая база 1С и адаптер в репозиторий не входят.

---

## Замечания

- Не держите одновременно оба стенда: общие `container_name` (`traefik`, `client-postgresdb17`, Airflow). `db-tests.ps1` перед `up` делает `compose down` для `dbpsql` и `dbmssql`.
- Логин Airflow в UI и в тестах: **admin/admin** (файл `ETLAirflow/config/simple_auth_manager_passwords.json`). Учётка `airflow/airflow` тоже есть.
- Seed msgqueue для Postgres: `070_msgqueue.sql` / `dbproject/ods/Dictionaries/messagequeue.sql`.

Контакты: [newlogin396@gmail.com](mailto:newlogin396@gmail.com)
