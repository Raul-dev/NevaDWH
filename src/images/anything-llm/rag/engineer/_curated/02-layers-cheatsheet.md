---
workspace: dwh-engineer
title: "Слои Landing ODS DWH — шпаргалка"
source: curated
status: test-stub
---

# Landing / ODS / DWH — шпаргалка для инженера

## Landing

- Приём данных «как есть» из источника.
- Часто через linked server / файлы / MQ.
- Не смешивать с витринами отчётов.

## ODS (Operational Data Store)

- В NevaDWH часто трактуется как **mini-DWH дневной активности**.
- Календарь (`DIM_Date`), FK на дату отчётности.
- Подходит для оперативных отчётов «за сегодня / за период».

## DWH

- Долгосрочная история, факты продаж/остатков и т.п.
- Измерения (DIM_*) и факты (FACT_*).
- ETL из ODS / staging в target.

## Генератор

Полный ZIP DWH и настройка проектов — в личном кабинете портала {{NEVA_RAG_BASE_URL}}/app/.  
Разовый SQL одного объекта — {{NEVA_RAG_BASE_URL}}/generator/ (это **Portal Helper**, не Engineer; всегда указывай `/generator/`).

## Тестовый режим ассистента

Модель маленькая: отвечай 3–6 предложениями, ссылайся на этот документ, не генерируй полный DDL.
