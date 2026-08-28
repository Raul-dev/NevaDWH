---
workspace: portal-helper
route: /docs/debug-sql/
title: "Debug SQL"
description: "Документация по инструменту Debug SQL"
source: nevadwh-astro
---

# Debug SQL

> Документация по инструменту Debug SQL

Канонический URL на портале: /docs/debug-sql/

# Debug SQL



Инструмент [Инструменты → Debug SQL](/debug-sql/) предназначен для отладки и проверки SQL-скриптов в контексте NevaDWH.




## Статус



Инструмент на [/debug-sql/](/debug-sql/) вызывает `POST api/ApplyProcLog`: на вход — текст процедуры, на выход — процедура с audit-обёртками.




## Связанный проект



Audit-база и утилита массового применения аудита к процедурам на SQL Server: [github.com/Raul-dev/Moex_CGate — src/ProcDebug](https://github.com/Raul-dev/Moex_CGate/tree/main/src/ProcDebug).




## Планируемое назначение




      - Проверка и разбор SQL, полученного из генератора или вручную.

      - Диагностика ошибок синтаксиса и несовместимости диалектов СУБД.

      - Связка с артефактами ODS/DWH до выкладки на целевой сервер.





Пока для генерации скриптов из метаданных 1С используйте [MetaData → SQL](/docs/metadata-sql/).
