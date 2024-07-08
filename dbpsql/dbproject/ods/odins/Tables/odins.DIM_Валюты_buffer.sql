do
$$
BEGIN
RAISE NOTICE 'Create table DIM_Валюты_buffer';
END;
$$;
CREATE TABLE IF NOT EXISTS odins."DIM_Валюты_buffer" (
    "buffer_id"   bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    "session_id"  bigint              NOT NULL,
    "msg_id"      uuid             NOT NULL,
    "msg"         text             NULL,
    "is_error"    boolean          NOT NULL DEFAULT false,
    "msgtype_id"  smallint        NOT NULL DEFAULT 1,
    "dt_create"   timestamp without time zone NOT NULL  default now(),
    "dt_update"   timestamp without time zone NOT NULL  default now()
);
