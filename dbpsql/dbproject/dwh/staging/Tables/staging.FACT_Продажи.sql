do
$$
BEGIN
RAISE NOTICE 'Create table staging.FACT_Продажи';
END;
$$;
CREATE TABLE IF NOT EXISTS staging."FACT_Продажи" (
    staging_id        bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    id                bigint NULL,
    session_id        bigint NULL,
    source_name       varchar(128) NULL,
    nkey              uuid NOT NULL,
    vkey              uuid NOT NULL,
    start_date        timestamp without time zone NULL,
    end_date          timestamp without time zone NULL,
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
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone        NULL
);
