do
$$
BEGIN
RAISE NOTICE 'Create foreign table ods.odins_DIM_Товары';
END;
$$;

CREATE FOREIGN TABLE IF NOT EXISTS ods."odins_DIM_Товары" (
    ods_id    bigint,
    nkey              uuid NOT NULL,
    "RefID"        uuid,
    "DeletionMark"        boolean,
    "Code"        varchar(128),
    "Description"        varchar(128),
    "Описание"        varchar(255),
    dt_update        timestamp without time zone, 
    dt_create        timestamp without time zone 
)
SERVER client_ods OPTIONS (schema_name 'odins', table_name 'DIM_Товары');
COMMENT ON FOREIGN TABLE ods."odins_DIM_Товары" IS '{"Description":"DIM_Товары"}';

