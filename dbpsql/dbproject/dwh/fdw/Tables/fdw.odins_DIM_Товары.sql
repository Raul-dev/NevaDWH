do
$$
BEGIN
RAISE NOTICE 'Create table fdw.DIM_Товары';
END;
$$;
DROP FOREIGN TABLE IF EXISTS fdw."odins_DIM_Товары";

CREATE FOREIGN TABLE IF NOT EXISTS fdw."odins_DIM_Товары" (
    dwh_session_id    bigint,
    nkey              uuid NOT NULL,
    "RefID"        uuid,
    "DeletionMark"        boolean,
    "Code"        varchar(128),
    "Description"        varchar(128),
    "Описание"        varchar(255),
    dt_create        timestamp without time zone default now()
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'DIM_Товары_history');
COMMENT ON FOREIGN TABLE fdw."odins_DIM_Товары" IS '{"Description":"DIM_Товары_history"}';

