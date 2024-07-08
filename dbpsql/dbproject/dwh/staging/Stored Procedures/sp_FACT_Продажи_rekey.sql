do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_FACT_Продажи_r"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_FACT_Продажи_r" (
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
    DROP TABLE IF EXISTS "tmp_FACT_Продажи";
    CREATE TEMPORARY TABLE "tmp_FACT_Продажи"(
        identificator uuid
    );

    INSERT INTO "tmp_FACT_Продажи"(identificator)
    SELECT "RefID" FROM staging."FACT_Продажи" as staging;

    UPDATE staging."FACT_Продажи" as staging
        SET id = COALESCE(trget.id, staging.staging_id),
        session_id = COALESCE(trget.session_id, staging.session_id),
        start_date = COALESCE(trget.start_date, staging.start_date)
    FROM staging."FACT_Продажи" as src
        LEFT JOIN target."FACT_Продажи" as trget ON trget.end_date = public."fn_GetMaxDate"() AND trget.nkey = src.nkey AND trget.vkey = src.vkey
    WHERE staging.staging_id = src.staging_id;

    INSERT INTO staging."FACT_Продажи" (
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        "RefID",
        "DeletionMark",
        "Number",
        "Posted",
        "Date",
        "ДатаОтгрузки",
        "Клиент",
        "ТипДоставки",
        "ПримерСоставногоТипа",
        "ПримерСоставногоТипа_ТипЗначения",
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
        "Number",
        "Posted",
        "Date",
        "ДатаОтгрузки",
        "Клиент",
        "ТипДоставки",
        "ПримерСоставногоТипа",
        "ПримерСоставногоТипа_ТипЗначения",
        par_session_id AS session_id_update,
        val_start_date AS dt_update
    FROM (
        SELECT source.*
            FROM target."FACT_Продажи" source
            WHERE source.end_date = public."fn_GetMaxDate"() AND
            EXISTS( SELECT 1 FROM staging."FACT_Продажи" as stg WHERE source.nkey = stg.nkey AND source.id <> stg.id )
        ) a;
    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;
    -- Child 
    DELETE FROM target."FACT_Продажи_Товары" AS b
    USING "tmp_FACT_Продажи" ll
    WHERE b."FACT_ПродажиRefID" = ll.identificator;
    UPDATE staging."FACT_Продажи_Товары" AS staging
        SET id = staging_id;

END;

$BODY$
LANGUAGE plpgsql;
