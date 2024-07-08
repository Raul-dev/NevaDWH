do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_DIM_Валюты_p"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_DIM_Валюты_p" (
    par_session_id in int DEFAULT NULL, 
    par_RowCount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
BEGIN

    UPDATE target."DIM_Валюты" AS trg SET
        session_id = stg.session_id,
        start_date = stg.start_date,
        end_date = stg.end_date,
        session_id_update = stg.session_id_update,
        dt_update = stg.dt_update,
        "RefID" = stg."RefID",
        "DeletionMark" = stg."DeletionMark",
        "Code" = stg."Code",
        "Description" = stg."Description",
        "ЗагружаетсяИзИнтернета" = stg."ЗагружаетсяИзИнтернета",
        "НаименованиеПолное" = stg."НаименованиеПолное",
        "Наценка" = stg."Наценка",
        "ОсновнаяВалюта" = stg."ОсновнаяВалюта",
        "ПараметрыПрописи" = stg."ПараметрыПрописи",
        "ФормулаРасчетаКурса" = stg."ФормулаРасчетаКурса",
        "СпособУстановкиКурса" = stg."СпособУстановкиКурса"
    FROM staging."DIM_Валюты" stg
    WHERE stg.id = trg.id;

    INSERT INTO target."DIM_Валюты" (
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        session_id_update,
        dt_update,
        dt_create,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "ЗагружаетсяИзИнтернета",
        "НаименованиеПолное",
        "Наценка",
        "ОсновнаяВалюта",
        "ПараметрыПрописи",
        "ФормулаРасчетаКурса",
        "СпособУстановкиКурса"
    )
    SELECT
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        session_id_update,
        dt_update,
        now() as dt_create,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "ЗагружаетсяИзИнтернета",
        "НаименованиеПолное",
        "Наценка",
        "ОсновнаяВалюта",
        "ПараметрыПрописи",
        "ФормулаРасчетаКурса",
        "СпособУстановкиКурса"
    FROM staging."DIM_Валюты"
    WHERE staging_id = id;
    UPDATE target."DIM_Валюты_Представления" AS trg SET
        session_id = stg.session_id,
        start_date = stg.start_date,
        end_date = stg.end_date,
        session_id_update = stg.session_id_update,
        dt_update = stg.dt_update,
        "DIM_ВалютыRefID" = stg."DIM_ВалютыRefID",
        "КодЯзыка" = stg."КодЯзыка",
        "ПараметрыПрописи" = stg."ПараметрыПрописи"
    FROM staging."DIM_Валюты_Представления" stg
    WHERE stg.id = trg.id;

    INSERT INTO target."DIM_Валюты_Представления" (
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        session_id_update,
        dt_update,
        dt_create,
        "DIM_ВалютыRefID",
        "КодЯзыка",
        "ПараметрыПрописи"
    )
    SELECT
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        session_id_update,
        dt_update,
        now() as dt_create,
        "DIM_ВалютыRefID",
        "КодЯзыка",
        "ПараметрыПрописи"
    FROM staging."DIM_Валюты_Представления"
    WHERE staging_id = id;

END;

$BODY$
LANGUAGE plpgsql;
