do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_DIM_Товары_r"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_DIM_Товары_r" (
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
    DROP TABLE IF EXISTS "tmp_DIM_Товары";
    CREATE TEMPORARY TABLE "tmp_DIM_Товары"(
        identificator uuid
    );

    INSERT INTO "tmp_DIM_Товары"(identificator)
    SELECT "RefID" FROM staging."DIM_Товары" as staging;

    UPDATE staging."DIM_Товары" as staging
        SET id = COALESCE(trget.id, staging.staging_id),
        session_id = COALESCE(trget.session_id, staging.session_id),
        start_date = COALESCE(trget.start_date, staging.start_date)
    FROM staging."DIM_Товары" as src
        LEFT JOIN target."DIM_Товары" as trget ON trget.end_date = public."fn_GetMaxDate"() AND trget.nkey = src.nkey AND trget.vkey = src.vkey
    WHERE staging.staging_id = src.staging_id;

    INSERT INTO staging."DIM_Товары" (
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
        "Описание",
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
        "Описание",
        par_session_id AS session_id_update,
        val_start_date AS dt_update
    FROM (
        SELECT source.*
            FROM target."DIM_Товары" source
            WHERE source.end_date = public."fn_GetMaxDate"() AND
            EXISTS( SELECT 1 FROM staging."DIM_Товары" as stg WHERE source.nkey = stg.nkey AND source.id <> stg.id )
        ) a;
    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;
    
END;

$BODY$
LANGUAGE plpgsql;
