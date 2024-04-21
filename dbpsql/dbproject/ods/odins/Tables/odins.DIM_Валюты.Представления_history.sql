do
$$
BEGIN
RAISE NOTICE 'Create table DIM_Валюты_Представления_history';
END;
$$;
CREATE TABLE IF NOT EXISTS "odins"."DIM_Валюты_Представления_history" (
    nkey              uuid NOT NULL,
    dwh_session_id    bigint,
    "DIM_ВалютыRefID"            uuid  NULL,
    "КодЯзыка"            varchar(10)  NULL,
    "ПараметрыПрописи"            varchar(200)  NULL,
    "dt_create"              timestamp without time zone         NULL default now());
