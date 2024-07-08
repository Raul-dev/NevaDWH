do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_DIM_Валюты_r"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_DIM_Валюты_r" (
    par_session_id in int DEFAULT NULL, 
    par_RowCount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount int;
    val_start_date timestamp without time zone;
    val_LocalCount bigint;
BEGIN

    SELECT create_session INTO val_start_date FROM session WHERE session_id = par_session_id;
    DROP TABLE IF EXISTS "tmp_DIM_Валюты";
    CREATE TEMPORARY TABLE "tmp_DIM_Валюты"(
        identificator uuid
    );

    INSERT INTO "tmp_DIM_Валюты"(identificator)
    SELECT "RefID" FROM staging."DIM_Валюты" as staging;

    UPDATE staging."DIM_Валюты" as staging
        SET id = COALESCE(trget.id, staging.staging_id),
        session_id = COALESCE(trget.session_id, staging.session_id),
        start_date = COALESCE(trget.start_date, staging.start_date)
    FROM staging."DIM_Валюты" as src
        LEFT JOIN target."DIM_Валюты" as trget ON trget.end_date = public."fn_GetMaxDate"() AND trget.nkey = src.nkey AND trget.vkey = src.vkey
    WHERE staging.staging_id = src.staging_id;

    INSERT INTO staging."DIM_Валюты" (
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
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
        "СпособУстановкиКурса",
        session_id_update,
        dt_update
    )
    SELECT
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        val_start_date as end_date,
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
        "СпособУстановкиКурса",
        par_session_id AS session_id_update,
        val_start_date AS dt_update
    FROM (
        SELECT source.*
            FROM target."DIM_Валюты" source
            WHERE source.end_date = public."fn_GetMaxDate"() AND
            EXISTS( SELECT 1 FROM staging."DIM_Валюты" as stg WHERE source.nkey = stg.nkey AND source.id <> stg.id )
        ) a;
    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;
    -- Child 
    DELETE FROM target."DIM_Валюты_Представления" AS b
    USING "tmp_DIM_Валюты" ll
    WHERE b."DIM_ВалютыRefID" = ll.identificator;
    UPDATE staging."DIM_Валюты_Представления" AS staging
        SET id = staging_id;

END;

$BODY$
LANGUAGE plpgsql;
