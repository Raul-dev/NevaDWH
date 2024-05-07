CREATE TABLE IF NOT EXISTS public.metadata
(
    nkey           uuid NOT NULL,
    namespace      character varying(256) COLLATE pg_catalog."default",
    namespace_ver  character varying(256) COLLATE pg_catalog."default",
    msg            text COLLATE pg_catalog."default",
    metaadapter_id smallint NOT NULL,
    dt_create      timestamp with time zone NOT NULL,
    CONSTRAINT "PK_metadata" PRIMARY KEY (nkey)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.metadata
    OWNER to postgres;