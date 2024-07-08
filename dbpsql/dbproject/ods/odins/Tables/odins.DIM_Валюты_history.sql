do
$$
BEGIN
RAISE NOTICE 'Create table DIM_Валюты_history';
END;
$$;
CREATE TABLE IF NOT EXISTS "odins"."DIM_Валюты_history" (
    nkey              uuid NOT NULL,
    dwh_session_id    bigint,
    "RefID"            uuid  NULL,
    "DeletionMark"            boolean  NULL,
    "Code"            varchar(128)  NULL,
    "Description"            varchar(128)  NULL,
    "ЗагружаетсяИзИнтернета"            boolean  NULL,
    "НаименованиеПолное"            varchar(50)  NULL,
    "Наценка"            decimal(10, 2)  NULL,
    "ОсновнаяВалюта"            varchar(36)  NULL,
    "ПараметрыПрописи"            varchar(200)  NULL,
    "ФормулаРасчетаКурса"            varchar(100)  NULL,
    "СпособУстановкиКурса"            varchar(500)  NULL,
    "dt_create"              timestamp without time zone         NULL default now());
