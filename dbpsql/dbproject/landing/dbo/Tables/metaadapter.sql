CREATE TABLE IF NOT EXISTS public.metaadapter 
(
    metaadapter_id smallint       NOT NULL,
    name             character varying(50) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "PK_metaadapter" PRIMARY KEY (metaadapter_id)
);

