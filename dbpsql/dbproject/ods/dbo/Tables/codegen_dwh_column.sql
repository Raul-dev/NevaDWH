
CREATE TABLE IF NOT EXISTS public.codegen_dwh_column
(
    codegen_dwh_column_id integer           NOT NULL,
    codegen_dwh_table_id  integer           NOT NULL,
    column_name           character varying(128) COLLATE pg_catalog."default" NOT NULL,
    data_type             character varying(128) COLLATE pg_catalog."default" NOT NULL,
    text_length           integer           NULL,
    precision             integer           NULL,
    scale                 integer           NULL,
    is_enable             boolean           CONSTRAINT DF_codegen_dwh_column_is_enable_DEFAULT DEFAULT ((true)) NOT NULL,
    is_versionkey         boolean           CONSTRAINT DF_codegen_dwh_column_is_versionkey_DEFAULT DEFAULT ((false)) NOT NULL,
    is_nulable            boolean           CONSTRAINT DF_codegen_dwh_column_is_nulable_DEFAULT DEFAULT ((true)) NOT NULL,
    null_value            character varying(128),
    CONSTRAINT "PK_codegen_dwh_column" PRIMARY KEY (codegen_dwh_column_id)

)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.codegen_dwh_column
    OWNER to postgres;
