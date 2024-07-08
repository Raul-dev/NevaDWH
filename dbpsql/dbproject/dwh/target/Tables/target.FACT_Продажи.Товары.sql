do
$$
BEGIN
RAISE NOTICE 'Create table target.FACT_Продажи_Товары';
END;
$$;

CREATE TABLE IF NOT EXISTS target."FACT_Продажи_Товары" (
    id                bigint NOT NULL,
    session_id        bigint NOT NULL,
    source_name       varchar(128) NOT NULL,
    nkey              uuid NOT NULL,
    vkey              uuid NOT NULL,
    start_date        timestamp without time zone NOT NULL,
    end_date          timestamp without time zone NOT NULL,
    "FACT_ПродажиRefID"         uuid  NOT NULL ,
    "Доставка"         boolean  NULL ,
    "Товар"         varchar(36)  NULL ,
    "Колличество"         decimal(12, 0)  NULL ,
    "Цена"         decimal(16, 4)  NULL ,
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone NOT NULL default now(),
    dt_create         timestamp without time zone NOT NULL default now(),
    CONSTRAINT "PK_target_FACT_Продажи_Товары" PRIMARY KEY (id));
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_target_FACT_Продажи_Товары" ON target."FACT_Продажи_Товары" (nkey);
