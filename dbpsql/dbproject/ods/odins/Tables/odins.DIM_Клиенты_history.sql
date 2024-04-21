do
$$
BEGIN
RAISE NOTICE 'Create table DIM_Клиенты_history';
END;
$$;
CREATE TABLE IF NOT EXISTS "odins"."DIM_Клиенты_history" (
    nkey              uuid NOT NULL,
    dwh_session_id    bigint,
    "RefID"            uuid  NULL,
    "DeletionMark"            boolean  NULL,
    "Code"            varchar(128)  NULL,
    "Description"            varchar(128)  NULL,
    "Контакт"            varchar(500)  NULL,
    "dt_create"              timestamp without time zone         NULL default now());
