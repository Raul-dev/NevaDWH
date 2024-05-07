do
$$
BEGIN
RAISE NOTICE 'Create table target.FACT_Продажи';
END;
$$;

CREATE TABLE IF NOT EXISTS target."FACT_Продажи" (
    id                bigint NOT NULL,
    session_id        bigint NOT NULL,
    source_name       varchar(128) NOT NULL,
    nkey              uuid NOT NULL,
    vkey              uuid NOT NULL,
    start_date        timestamp without time zone NOT NULL,
    end_date          timestamp without time zone NOT NULL,
    "RefID"         uuid  NOT NULL ,
    "DeletionMark"         boolean  NULL ,
    "Number"         integer  NULL ,
    "Posted"         boolean  NULL ,
    "Date"         timestamp  NULL ,
    "ДатаОтгрузки"         timestamp  NULL ,
    "Клиент"         varchar(36)  NULL ,
    "ТипДоставки"         varchar(500)  NULL ,
    "ПримерСоставногоТипа"         varchar(36)  NULL ,
    "ПримерСоставногоТипа_ТипЗначения"         varchar(128)  NULL ,
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone NOT NULL default now(),
    dt_create         timestamp without time zone NOT NULL default now(),
    CONSTRAINT "PK_target_FACT_Продажи" PRIMARY KEY (id));
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_target_FACT_Продажи" ON target."FACT_Продажи" (nkey);
