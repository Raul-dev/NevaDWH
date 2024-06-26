do
$$
BEGIN
RAISE NOTICE 'Create table DIM_Клиенты';
END;
$$;

CREATE TABLE IF NOT EXISTS odins."DIM_Клиенты" (
    ods_id        bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ) PRIMARY KEY,
    nkey          uuid NOT NULL,
    "RefID"        uuid  NOT NULL  ,
    "DeletionMark"        boolean   NULL  ,
    "Code"        varchar(128)   NULL  ,
    "Description"        varchar(128)   NULL  ,
    "Контакт"        varchar(500)   NULL  ,
    dt_update     timestamp without time zone default now(),
    dt_create     timestamp without time zone default now()
);

COMMENT ON TABLE "odins"."DIM_Клиенты" IS '{"Description":"DIM_Клиенты"}';

CREATE UNIQUE INDEX IF NOT EXISTS "IDX_odins_DIM_Клиенты" ON odins."DIM_Клиенты" (nkey);
