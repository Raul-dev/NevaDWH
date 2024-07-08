do
$$
BEGIN
RAISE NOTICE 'Create foreign table ods.odins_DIM_Валюты';
END;
$$;

CREATE FOREIGN TABLE IF NOT EXISTS ods."odins_DIM_Валюты" (
    ods_id    bigint,
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
    dt_update        timestamp without time zone, 
    dt_create        timestamp without time zone 
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'DIM_Валюты');
COMMENT ON FOREIGN TABLE ods."odins_DIM_Валюты" IS '{"Description":"DIM_Валюты"}';

