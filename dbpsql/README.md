# dbpsql — PostgreSQL-стенд NevaDWH

Локальный Docker Compose для **PostgreSQL**-версии клиента (ODS / DWH / Landing в контейнере `client-postgresdb17`).

Подробности стека, учёток и **автотестов** — в корневом [README.md](../README.md).

## Быстрый запуск

```powershell
cd .\dbpsql
docker compose build
.\start.ps1              # первый раз — от администратора
.\start.ps1 -IsUpdate
.\start.ps1 -ScriptsOnly # только сборка 005..070 для initdb
```

## Автотест

```powershell
cd ..
.\db-tests.ps1 dbpsql
.\db-tests.ps1 dbpsql -SkipCompose
.\db-tests.ps1 dbpsql -Build
```

## Учётки (кратко)

| | |
|--|--|
| Airflow / Rabbit | **admin / admin** |
| Postgres (host) | `localhost:54321`, `postgres` / `postgres` |
| ODS / DWH | `newadwh_ods` / `newadwh_dwh` |
| MQ Swagger | http://localhost:8090/v1/mq/swagger |
| Airflow UI | http://localhost:8080 |
| Admin UI | http://localhost:8100 |

Образы приложений: Docker Hub `raulamailru/nevadwh-*`. Airflow/Rabbit: локальная сборка из `./images`.
