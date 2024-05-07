
CREATE TABLE IF NOT EXISTS public.codegen_enable_type
(
    codegen_enable_type_id  smallint NOT NULL,
    description   character varying(256) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "PK_codegen_enable_type" PRIMARY KEY (codegen_enable_type_id)
)


TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.codegen_enable_type
    OWNER to postgres;