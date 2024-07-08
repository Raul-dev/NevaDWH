do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_FACT_Продажи_t"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_FACT_Продажи_t" (
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


    TRUNCATE TABLE "staging"."FACT_Продажи";
    SELECT MAX(id) into val_LastTargetID FROM "target"."FACT_Продажи";

    SELECT pg_get_serial_sequence('staging."FACT_Продажи"', 'staging_id') INTO val_tmp;
    val_LastTargetID := COALESCE(val_LastTargetID, 0) + 1;
    PERFORM setval(val_tmp, val_LastTargetID );
    
    SELECT name INTO val_source_name FROM data_source d WHERE d.data_source_id =  1;
    SELECT dwh_session_id INTO val_dwh_session_id FROM session s WHERE session_id = par_session_id;
    SELECT create_session INTO val_start_date FROM session s WHERE session_id = par_session_id;

    INSERT INTO staging."FACT_Продажи" (
        "session_id",
        "source_name",
        "nkey",
        "vkey",
        "start_date",
        "end_date",
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
        par_session_id AS "session_id",
        val_source_name AS "source_name",
        "nkey",
        nkey AS "vkey",
        val_start_date AS "start_date",
        "fn_GetMaxDate"() AS "end_date",
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
    FROM fdw."odins_FACT_Продажи" tmp
    WHERE dwh_session_id = val_dwh_session_id;
    GET DIAGNOSTICS var_RowCount = ROW_COUNT;
    par_RowCount := par_RowCount + var_RowCount;
    

-- Child FACT_Продажи_Товары 
    TRUNCATE TABLE "staging"."FACT_Продажи_Товары";
    SELECT MAX(id) into val_LastTargetID FROM "target"."FACT_Продажи_Товары";
    IF NOT val_LastTargetID is NULL AND val_LastTargetID >= 1 THEN
        SELECT pg_get_serial_sequence('staging."FACT_Продажи_Товары"', 'staging_id') INTO val_tmp ;
        val_LastTargetID := val_LastTargetID + 1;
        SELECT setval(val_tmp, val_LastTargetID );
    END IF;
    INSERT INTO staging."FACT_Продажи_Товары" (
        "session_id",
        "source_name",
        "nkey",
        "vkey",
        "start_date",
        "end_date",
        "FACT_ПродажиRefID",
        "Доставка",
        "Товар",
        "Колличество",
        "Цена",
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
        "FACT_ПродажиRefID",
        "Доставка",
        "Товар",
        "Колличество",
        "Цена",
        par_session_id AS session_id_update,
        val_start_date AS dt_update
    FROM fdw."odins_FACT_Продажи_Товары" tmp
    WHERE dwh_session_id = val_dwh_session_id;
    GET DIAGNOSTICS var_RowCount = ROW_COUNT;
    par_RowCount := par_RowCount + var_RowCount;
    
END;

$BODY$
LANGUAGE plpgsql;
