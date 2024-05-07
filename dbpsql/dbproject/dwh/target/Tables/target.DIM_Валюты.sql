do
$$
BEGIN
RAISE NOTICE 'Create table target.DIM_Валюты';
END;
$$;

CREATE TABLE IF NOT EXISTS target."DIM_Валюты" (
    id                bigint NOT NULL,
    session_id        bigint NOT NULL,
    source_name       varchar(128) NOT NULL,
    nkey              uuid NOT NULL,
    vkey              uuid NOT NULL,
    start_date        timestamp without time zone NOT NULL,
    end_date          timestamp without time zone NOT NULL,
    "RefID"         uuid  NOT NULL ,
    "DeletionMark"         boolean  NULL ,
    "Code"         varchar(128)  NULL ,
    "Description"         varchar(128)  NULL ,
    "ЗагружаетсяИзИнтернета"         boolean  NULL ,
    "НаименованиеПолное"         varchar(50)  NULL ,
    "Наценка"         decimal(10, 2)  NULL ,
    "ОсновнаяВалюта"         varchar(36)  NULL ,
    "ПараметрыПрописи"         varchar(200)  NULL ,
    "ФормулаРасчетаКурса"         varchar(100)  NULL ,
    "СпособУстановкиКурса"         varchar(500)  NULL ,
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone NOT NULL default now(),
    dt_create         timestamp without time zone NOT NULL default now(),
    CONSTRAINT "PK_target_DIM_Валюты" PRIMARY KEY (id));
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_target_DIM_Валюты" ON target."DIM_Валюты" (nkey);
