do
$$
BEGIN
RAISE NOTICE 'Create table FACT_Продажи_Товары_history';
END;
$$;
CREATE TABLE IF NOT EXISTS "odins"."FACT_Продажи_Товары_history" (
    nkey              uuid NOT NULL,
    dwh_session_id    bigint,
    "FACT_ПродажиRefID"            uuid  NULL,
    "Доставка"            boolean  NULL,
    "Товар"            varchar(36)  NULL,
    "Колличество"            decimal(12, 0)  NULL,
    "Цена"            decimal(16, 4)  NULL,
    "dt_create"              timestamp without time zone         NULL default now());
