do
$$
BEGIN
RAISE NOTICE 'Create table target.DIM_Клиенты';
END;
$$;

CREATE TABLE IF NOT EXISTS target."DIM_Клиенты" (
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
    "Контакт"         varchar(500)  NULL ,
    session_id_update bigint NOT NULL,
    dt_update         timestamp without time zone NOT NULL default now(),
    dt_create         timestamp without time zone NOT NULL default now(),
    CONSTRAINT "PK_target_DIM_Клиенты" PRIMARY KEY (id));
CREATE UNIQUE INDEX IF NOT EXISTS "IDX_target_DIM_Клиенты" ON target."DIM_Клиенты" (nkey);
