
CREATE TABLE IF NOT EXISTS public.data_source(
    data_source_id smallint       NOT NULL,
    name           character varying(100) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "PK_data_source" PRIMARY KEY (data_source_id)
);
