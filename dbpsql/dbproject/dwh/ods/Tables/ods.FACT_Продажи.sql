do
$$
BEGIN
RAISE NOTICE 'Create foreign table ods.odins_FACT_Продажи';
END;
$$;

CREATE FOREIGN TABLE IF NOT EXISTS ods."odins_FACT_Продажи" (
    ods_id    bigint,
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
    dt_update        timestamp without time zone, 
    dt_create        timestamp without time zone 
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'FACT_Продажи');
COMMENT ON FOREIGN TABLE ods."odins_FACT_Продажи" IS '{"Description":"FACT_Продажи"}';

