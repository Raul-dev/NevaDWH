do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_DIM_Товары_t"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_DIM_Товары_t" (
    par_session_id in int DEFAULT NULL, 
    par_RowCount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount int;
    val_start_date timestamp without time zone;
    val_dwh_session_id bigint;
    val_LastTargetID bigint;
    val_LocalCount bigint;
    val_source_name varchar(128);
    val_tmp varchar(128); 
BEGIN


    TRUNCATE TABLE "staging"."DIM_Товары";
    SELECT MAX(id) into val_LastTargetID FROM "target"."DIM_Товары";

    SELECT pg_get_serial_sequence('staging."DIM_Товары"', 'staging_id') INTO val_tmp;
    val_LastTargetID := COALESCE(val_LastTargetID, 0) + 1;
    PERFORM setval(val_tmp, val_LastTargetID );
    
    SELECT name INTO val_source_name FROM data_source d WHERE d.data_source_id =  1;
    SELECT dwh_session_id INTO val_dwh_session_id FROM session s WHERE session_id = par_session_id;
    SELECT create_session INTO val_start_date FROM session s WHERE session_id = par_session_id;

    INSERT INTO staging."DIM_Товары" (
        "session_id",
        "source_name",
        "nkey",
        "vkey",
        "start_date",
        "end_date",
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Описание",
        session_id_update,
        dt_update
    )
    SELECT
        par_session_id AS "session_id",
        val_source_name AS "source_name",
        "nkey",
        nkey AS "vkey",
        val_start_date AS "start_date",
        "fn_GetMaxDate"() AS "end_date",
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Описание",
        par_session_id AS session_id_update,
        val_start_date AS dt_update
    FROM fdw."odins_DIM_Товары" tmp
    WHERE dwh_session_id = val_dwh_session_id;
    GET DIAGNOSTICS var_RowCount = ROW_COUNT;
    par_RowCount := par_RowCount + var_RowCount;
    

END;

$BODY$
LANGUAGE plpgsql;
