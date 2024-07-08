do
$$
BEGIN
RAISE NOTICE 'Create table fdw.FACT_Продажи';
END;
$$;
DROP FOREIGN TABLE IF EXISTS fdw."odins_FACT_Продажи";

CREATE FOREIGN TABLE IF NOT EXISTS fdw."odins_FACT_Продажи" (
    dwh_session_id    bigint,
    nkey              uuid NOT NULL,
    "RefID"        uuid,
    "DeletionMark"        boolean,
    "Number"        integer,
    "Posted"        boolean,
    "Date"        timestamp,
    "ДатаОтгрузки"        timestamp,
    "Клиент"        varchar(36),
    "ТипДоставки"        varchar(500),
    "ПримерСоставногоТипа"        varchar(36),
    "ПримерСоставногоТипа_ТипЗначения"        varchar(128),
    dt_create        timestamp without time zone default now()
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'FACT_Продажи_history');
COMMENT ON FOREIGN TABLE fdw."odins_FACT_Продажи" IS '{"Description":"FACT_Продажи_history"}';

