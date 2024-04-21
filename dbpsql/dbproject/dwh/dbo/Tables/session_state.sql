CREATE TABLE IF NOT EXISTS public.session_state 
(
    session_state_id smallint       NOT NULL,
    name             character varying(100) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "PK_session_state" PRIMARY KEY (session_state_id )
);

