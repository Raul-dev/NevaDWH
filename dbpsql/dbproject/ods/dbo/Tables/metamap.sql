﻿
CREATE TABLE IF NOT EXISTS public.metamap
(
    metamap_id     smallint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 32767 CACHE 1 ),
    msg_key        character varying(128) COLLATE pg_catalog."default" NOT NULL,
    table_name     character varying(128) COLLATE pg_catalog."default" NOT NULL,
    metaadapter_id smallint NOT NULL,
    namespace      character varying(256) COLLATE pg_catalog."default",
    namespace_ver  character varying(256) COLLATE pg_catalog."default",
    etl_query      character varying(256) COLLATE pg_catalog."default",
    import_query   character varying(256) COLLATE pg_catalog."default",
    is_enable      boolean NOT NULL,
    CONSTRAINT "PK_metamap" PRIMARY KEY (metamap_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.metamap
    OWNER to postgres;