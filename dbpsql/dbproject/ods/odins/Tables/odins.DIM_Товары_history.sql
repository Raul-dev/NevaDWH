do
$$
BEGIN
RAISE NOTICE 'Create table DIM_Товары_history';
END;
$$;
CREATE TABLE IF NOT EXISTS "odins"."DIM_Товары_history" (
    nkey              uuid NOT NULL,
    dwh_session_id    bigint,
    "RefID"            uuid  NULL,
    "DeletionMark"            boolean  NULL,
    "Code"            varchar(128)  NULL,
    "Description"            varchar(128)  NULL,
    "Описание"            varchar(255)  NULL,
    "dt_create"              timestamp without time zone         NULL default now());
