do
$$
BEGIN
RAISE NOTICE 'Create table target.DIM_Товары';
END;
$$;

CREATE TABLE IF NOT EXISTS target."DIM_Товары" (
    id                bigint NOT NULL,
    session_id        bigint NOT NULL,
    source_name       varchar(128) NOT NULL,
    nkey              uuid NOT NULL,
    vkey              uuid NOT NULL,
    start_date        timestamp without time zone NOT NULL,
    end_date          timestamp without time zone NOT NULL,
    "RefID"         uuid  NOT NULL ,
    "DeletionMark"         boolean  NULL ,
    "Code"         varchar(128)  NULL ,
    "Description"         varchar(128)  NULL ,
    "Описание"         varchar(255)  NULL ,
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone NOT NULL default now(),
    dt_create         timestamp without time zone NOT NULL default now(),
    CONSTRAINT "PK_target_DIM_Товары" PRIMARY KEY (id));
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_target_DIM_Товары" ON target."DIM_Товары" (nkey);
