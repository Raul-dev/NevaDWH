
CREATE TABLE IF NOT EXISTS public.codegen_dwh_table
(

    codegen_dwh_table_id integer           NOT NULL,
    codegen_id            integer           NOT NULL,
    table_name            character varying(128) COLLATE pg_catalog."default" NOT NULL,
    is_root               boolean           NOT NULL,
    is_enable             boolean           NOT NULL,
    dwh_table_name        character varying(128) COLLATE pg_catalog."default" NOT NULL,
    is_vkey_session       boolean           CONSTRAINT DF_codegen_dwh_table_is_vkey_session_DEFAULT DEFAULT ((true)) NOT NULL,
    is_vkey_sourcename    boolean           CONSTRAINT DF_codegen_dwh_table_is_vkey_sourcename_DEFAULT DEFAULT ((true)) NOT NULL,
    is_historical         boolean           CONSTRAINT DF_codegen_dwh_table_is_historical_DEFAULT DEFAULT ((true)) NOT NULL,
    CONSTRAINT "PK_codegen_dwh_table" PRIMARY KEY (codegen_dwh_table_id)

)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.codegen_dwh_table
    OWNER to postgres;
