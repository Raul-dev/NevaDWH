do
$$
BEGIN
RAISE NOTICE 'Create table target.DIM_Валюты_Представления';
END;
$$;

CREATE TABLE IF NOT EXISTS target."DIM_Валюты_Представления" (
    id                bigint NOT NULL,
    session_id        bigint NOT NULL,
    source_name       varchar(128) NOT NULL,
    nkey              uuid NOT NULL,
    vkey              uuid NOT NULL,
    start_date        timestamp without time zone NOT NULL,
    end_date          timestamp without time zone NOT NULL,
    "DIM_ВалютыRefID"         uuid  NOT NULL ,
    "КодЯзыка"         varchar(10)  NULL ,
    "ПараметрыПрописи"         varchar(200)  NULL ,
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone NOT NULL default now(),
    dt_create         timestamp without time zone NOT NULL default now(),
    CONSTRAINT "PK_target_DIM_Валюты_Представления" PRIMARY KEY (id));
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_target_DIM_Валюты_Представления" ON target."DIM_Валюты_Представления" (nkey);
