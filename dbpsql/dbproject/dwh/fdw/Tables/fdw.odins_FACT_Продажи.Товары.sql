do
$$
BEGIN
RAISE NOTICE 'Create table fdw.FACT_Продажи_Товары';
END;
$$;
DROP FOREIGN TABLE IF EXISTS fdw."odins_FACT_Продажи_Товары";

CREATE FOREIGN TABLE IF NOT EXISTS fdw."odins_FACT_Продажи_Товары" (
    dwh_session_id    bigint,
    nkey              uuid NOT NULL,
    "FACT_ПродажиRefID"        uuid,
    "Доставка"        boolean,
    "Товар"        varchar(36),
    "Колличество"        decimal(12, 0),
    "Цена"        decimal(16, 4),
    dt_create        timestamp without time zone default now()
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'FACT_Продажи_Товары_history');
COMMENT ON FOREIGN TABLE fdw."odins_FACT_Продажи_Товары" IS '{"Description":"FACT_Продажи.Товары_history"}';

