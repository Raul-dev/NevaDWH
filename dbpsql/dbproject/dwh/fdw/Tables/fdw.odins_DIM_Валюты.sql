do
$$
BEGIN
RAISE NOTICE 'Create table fdw.DIM_Валюты';
END;
$$;
DROP FOREIGN TABLE IF EXISTS fdw."odins_DIM_Валюты";

CREATE FOREIGN TABLE IF NOT EXISTS fdw."odins_DIM_Валюты" (
    dwh_session_id    bigint,
    nkey              uuid NOT NULL,
    "RefID"        uuid,
    "DeletionMark"        boolean,
    "Code"        varchar(128),
    "Description"        varchar(128),
    "ЗагружаетсяИзИнтернета"        boolean,
    "НаименованиеПолное"        varchar(50),
    "Наценка"        decimal(10, 2),
    "ОсновнаяВалюта"        varchar(36),
    "ПараметрыПрописи"        varchar(200),
    "ФормулаРасчетаКурса"        varchar(100),
    "СпособУстановкиКурса"        varchar(500),
    dt_create        timestamp without time zone default now()
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'DIM_Валюты_history');
COMMENT ON FOREIGN TABLE fdw."odins_DIM_Валюты" IS '{"Description":"DIM_Валюты_history"}';

