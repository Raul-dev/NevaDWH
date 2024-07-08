﻿CREATE TABLE IF NOT EXISTS public.codegen
(
    codegen_id integer NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    namespace character varying(256) COLLATE pg_catalog."default" NOT NULL,
    schema character varying(128) COLLATE pg_catalog."default" NOT NULL,
    table_name character varying(128) COLLATE pg_catalog."default" NOT NULL,
    ods_enable_type smallint NULL,
    dwh_enable_type smallint NULL,
    landing_enable_type smallint NULL,
    CONSTRAINT "PK_codegen" PRIMARY KEY (codegen_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.codegen
    OWNER to postgres;