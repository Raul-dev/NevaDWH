do
$$
BEGIN
RAISE NOTICE 'Create table fdw.DIM_Валюты_Представления';
END;
$$;
DROP FOREIGN TABLE IF EXISTS fdw."odins_DIM_Валюты_Представления";

CREATE FOREIGN TABLE IF NOT EXISTS fdw."odins_DIM_Валюты_Представления" (
    dwh_session_id    bigint,
    nkey              uuid NOT NULL,
    "DIM_ВалютыRefID"        uuid,
    "КодЯзыка"        varchar(10),
    "ПараметрыПрописи"        varchar(200),
    dt_create        timestamp without time zone default now()
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'DIM_Валюты_Представления_history');
COMMENT ON FOREIGN TABLE fdw."odins_DIM_Валюты_Представления" IS '{"Description":"DIM_Валюты.Представления_history"}';

