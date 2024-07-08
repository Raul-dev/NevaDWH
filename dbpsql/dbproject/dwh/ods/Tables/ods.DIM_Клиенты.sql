do
$$
BEGIN
RAISE NOTICE 'Create foreign table ods.odins_DIM_Клиенты';
END;
$$;

CREATE FOREIGN TABLE IF NOT EXISTS ods."odins_DIM_Клиенты" (
    ods_id    bigint,
    nkey              uuid NOT NULL,
    "RefID"        uuid,
    "DeletionMark"        boolean,
    "Code"        varchar(128),
    "Description"        varchar(128),
    "Контакт"        varchar(500),
    dt_update        timestamp without time zone, 
    dt_create        timestamp without time zone 
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'DIM_Клиенты');
COMMENT ON FOREIGN TABLE ods."odins_DIM_Клиенты" IS '{"Description":"DIM_Клиенты"}';

