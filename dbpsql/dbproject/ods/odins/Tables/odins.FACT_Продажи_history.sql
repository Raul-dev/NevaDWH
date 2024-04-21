do
$$
BEGIN
RAISE NOTICE 'Create table FACT_Продажи_history';
END;
$$;
CREATE TABLE IF NOT EXISTS "odins"."FACT_Продажи_history" (
    nkey              uuid NOT NULL,
    dwh_session_id    bigint,
    "RefID"            uuid  NULL,
    "DeletionMark"            boolean  NULL,
    "Number"            integer  NULL,
    "Posted"            boolean  NULL,
    "Date"            timestamp  NULL,
    "ДатаОтгрузки"            timestamp  NULL,
    "Клиент"            varchar(36)  NULL,
    "ТипДоставки"            varchar(500)  NULL,
    "ПримерСоставногоТипа"            varchar(36)  NULL,
    "ПримерСоставногоТипа_ТипЗначения"            varchar(128)  NULL,
    "dt_create"              timestamp without time zone         NULL default now());
