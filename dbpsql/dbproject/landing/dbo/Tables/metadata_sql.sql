﻿CREATE TABLE IF NOT EXISTS public.metadata_sql
(
    "id" bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ) ,
    "guid" uuid NULL,
    "column_order" int NOT NULL,
    "s_schema_type" varchar(128) ,
    "s_table_name" varchar(128) ,
    "s_column_name" varchar(128) ,
    "s_data_type" varchar(128) ,
    "s_text_length" varchar(128) ,
    "s_precision" varchar(128) ,
    "s_scale" varchar(128) ,
    "s_is_nkey" boolean NOT NULL,
    "t_star_name" varchar(128) ,
    "t_table_name" varchar(128) ,
    "t_column_name" varchar(128) ,
    "t_data_type" varchar(128) ,
    "t_text_length" varchar(128) ,
    "t_precision" varchar(128) ,
    "t_scale" varchar(128) ,
    "t_is_nkey" boolean NOT NULL,
    "t_is_fkey" boolean NOT NULL,
    "t_is_present" boolean NOT NULL,
    "t_is_vkey" boolean NOT NULL,
    "t_history_type" varchar(100) ,
    "t_is_aggr" boolean NOT NULL,
    "t_aggr_type" varchar(100) ,
    "description" varchar(4000) ,
    CONSTRAINT "PK_metadata_sql" PRIMARY KEY (id)
) 


TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.metadata_sql
    OWNER to postgres;