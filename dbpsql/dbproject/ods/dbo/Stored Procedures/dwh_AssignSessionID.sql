do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "dwh_AssignSessionID"';
END;
$$;

-- SELECT * FROM dwh_processing_details
-- call public."dwh_AssignSessionID" (null, null)
CREATE OR REPLACE PROCEDURE "dwh_AssignSessionID" (
    INOUT par_dwh_session_id bigint DEFAULT NULL::bigint,
    INOUT par_rowcount bigint DEFAULT NULL::bigint,
    INOUT par_create_session timestamp DEFAULT NULL::timestamp
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
    var_LocalRowCount INTEGER;
BEGIN

    par_rowcount:= 0;
    IF NOT par_dwh_session_id IS NULL AND par_dwh_session_id != -1 THEN

        SELECT INTO par_dwh_session_id, par_rowcount, par_create_session
        FROM (
            SELECT s.dwh_session_id, sum(row_count) as row_count, MAX(s.create_session) AS create_session
            FROM dwh_session s
                INNER JOIN dwh_processing_details p ON p.dwh_session_id = s.dwh_session_id
            WHERE dwh_session_state_id = 2 AND s.dwh_session_id = par_dwh_session_id
            GROUP BY s.dwh_session_id
        ) s;
        RETURN ;
    END IF;

    IF par_dwh_session_id IS NULL OR par_dwh_session_id = -1 THEN
        SELECT  min(dwh_session_id) into par_dwh_session_id FROM dwh_session WHERE (par_dwh_session_id IS NULL OR par_dwh_session_id != -1) AND dwh_session_state_id = 2;

        RAISE NOTICE 'N1 par_dwh_session_id  %', par_dwh_session_id;

        IF NOT par_dwh_session_id IS NULL THEN
            SELECT COALESCE(create_session,now()) INTO par_create_session FROM dwh_session WHERE dwh_session_id = par_dwh_session_id; 
            SELECT COALESCE(SUM(row_count),0) INTO par_rowcount
            FROM dwh_processing_details WHERE dwh_session_id = par_dwh_session_id
            GROUP BY dwh_session_id;
            RAISE NOTICE 'N2 par_dwh_session_id  %', par_dwh_session_id;
            RETURN;
        END IF;

        call public."dwh_SaveSessionState" ( par_dwh_session_id::bigint , 1::smallint, 1::smallint, null::varchar(4000) );
    END IF;
    
    IF var_RowCount > 0 THEN
        call dwh_SaveSessionState (par_dwh_session_id, 2, null,null);
    END IF;
--DIM_Валюты
    LOCK TABLE odins."DIM_Валюты" IN ROW EXCLUSIVE MODE;
    DROP TABLE IF EXISTS "tmp_DIM_Валюты";
    CREATE TEMPORARY TABLE "tmp_DIM_Валюты"(
        ods_id bigint Primary Key,
        "RefID" uuid
    );
    INSERT INTO "tmp_DIM_Валюты" (
        ods_id, "RefID"
    )
    SELECT ods_id, "RefID" FROM odins."DIM_Валюты" FOR UPDATE;

    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;

    IF var_rowcount > 0 THEN
        INSERT INTO dwh_processing_details( dwh_session_id, schema_name, table_name, row_count)
        SELECT par_dwh_session_id, 'odins', 'DIM_Валюты',var_rowcount;
    END IF;

    DELETE FROM odins."DIM_Валюты_history" WHERE dwh_session_id = par_dwh_session_id;

    INSERT INTO odins."DIM_Валюты_history"(
        nkey,
        dwh_session_id,
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
        dt_create
    )
    SELECT
        b.nkey,
        par_dwh_session_id AS dwh_session_id,
        b."RefID",
        b."DeletionMark",
        b."Code",
        b."Description",
        b."ЗагружаетсяИзИнтернета",
        b."НаименованиеПолное",
        b."Наценка",
        b."ОсновнаяВалюта",
        b."ПараметрыПрописи",
        b."ФормулаРасчетаКурса",
        b."СпособУстановкиКурса",
        now() AS dt_create
    FROM odins."DIM_Валюты" b
        INNER JOIN "tmp_DIM_Валюты" ll ON b.ods_id = ll.ods_id;


    DELETE FROM odins."DIM_Валюты_Представления_history" WHERE dwh_session_id = par_dwh_session_id;

    INSERT INTO odins."DIM_Валюты_Представления_history"(
        nkey,
        dwh_session_id,
        "DIM_ВалютыRefID",
        "КодЯзыка",
        "ПараметрыПрописи",
        dt_create
    )
    SELECT
        b.nkey,
        par_dwh_session_id AS dwh_session_id,
        b."DIM_ВалютыRefID",
        b."КодЯзыка",
        b."ПараметрыПрописи",
        now() AS dt_create
    FROM odins."DIM_Валюты_Представления" b
        INNER JOIN "tmp_DIM_Валюты" ll ON b."DIM_ВалютыRefID" = ll."RefID";


    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;

    IF var_rowcount > 0 THEN
        INSERT INTO dwh_processing_details( dwh_session_id, schema_name, table_name, row_count)
        SELECT par_dwh_session_id, 'odins', 'DIM_Валюты_Представления',var_rowcount;
    END IF;

    COMMIT;
--DIM_Клиенты
    LOCK TABLE odins."DIM_Клиенты" IN ROW EXCLUSIVE MODE;
    DROP TABLE IF EXISTS "tmp_DIM_Клиенты";
    CREATE TEMPORARY TABLE "tmp_DIM_Клиенты"(
        ods_id bigint Primary Key,
        "RefID" uuid
    );
    INSERT INTO "tmp_DIM_Клиенты" (
        ods_id, "RefID"
    )
    SELECT ods_id, "RefID" FROM odins."DIM_Клиенты" FOR UPDATE;

    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;

    IF var_rowcount > 0 THEN
        INSERT INTO dwh_processing_details( dwh_session_id, schema_name, table_name, row_count)
        SELECT par_dwh_session_id, 'odins', 'DIM_Клиенты',var_rowcount;
    END IF;

    DELETE FROM odins."DIM_Клиенты_history" WHERE dwh_session_id = par_dwh_session_id;

    INSERT INTO odins."DIM_Клиенты_history"(
        nkey,
        dwh_session_id,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Контакт",
        dt_create
    )
    SELECT
        b.nkey,
        par_dwh_session_id AS dwh_session_id,
        b."RefID",
        b."DeletionMark",
        b."Code",
        b."Description",
        b."Контакт",
        now() AS dt_create
    FROM odins."DIM_Клиенты" b
        INNER JOIN "tmp_DIM_Клиенты" ll ON b.ods_id = ll.ods_id;

    COMMIT;
--DIM_Товары
    LOCK TABLE odins."DIM_Товары" IN ROW EXCLUSIVE MODE;
    DROP TABLE IF EXISTS "tmp_DIM_Товары";
    CREATE TEMPORARY TABLE "tmp_DIM_Товары"(
        ods_id bigint Primary Key,
        "RefID" uuid
    );
    INSERT INTO "tmp_DIM_Товары" (
        ods_id, "RefID"
    )
    SELECT ods_id, "RefID" FROM odins."DIM_Товары" FOR UPDATE;

    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;

    IF var_rowcount > 0 THEN
        INSERT INTO dwh_processing_details( dwh_session_id, schema_name, table_name, row_count)
        SELECT par_dwh_session_id, 'odins', 'DIM_Товары',var_rowcount;
    END IF;

    DELETE FROM odins."DIM_Товары_history" WHERE dwh_session_id = par_dwh_session_id;

    INSERT INTO odins."DIM_Товары_history"(
        nkey,
        dwh_session_id,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Описание",
        dt_create
    )
    SELECT
        b.nkey,
        par_dwh_session_id AS dwh_session_id,
        b."RefID",
        b."DeletionMark",
        b."Code",
        b."Description",
        b."Описание",
        now() AS dt_create
    FROM odins."DIM_Товары" b
        INNER JOIN "tmp_DIM_Товары" ll ON b.ods_id = ll.ods_id;

    COMMIT;
--FACT_Продажи
    LOCK TABLE odins."FACT_Продажи" IN ROW EXCLUSIVE MODE;
    DROP TABLE IF EXISTS "tmp_FACT_Продажи";
    CREATE TEMPORARY TABLE "tmp_FACT_Продажи"(
        ods_id bigint Primary Key,
        "RefID" uuid
    );
    INSERT INTO "tmp_FACT_Продажи" (
        ods_id, "RefID"
    )
    SELECT ods_id, "RefID" FROM odins."FACT_Продажи" FOR UPDATE;

    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;

    IF var_rowcount > 0 THEN
        INSERT INTO dwh_processing_details( dwh_session_id, schema_name, table_name, row_count)
        SELECT par_dwh_session_id, 'odins', 'FACT_Продажи',var_rowcount;
    END IF;

    DELETE FROM odins."FACT_Продажи_history" WHERE dwh_session_id = par_dwh_session_id;

    INSERT INTO odins."FACT_Продажи_history"(
        nkey,
        dwh_session_id,
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
        dt_create
    )
    SELECT
        b.nkey,
        par_dwh_session_id AS dwh_session_id,
        b."RefID",
        b."DeletionMark",
        b."Number",
        b."Posted",
        b."Date",
        b."ДатаОтгрузки",
        b."Клиент",
        b."ТипДоставки",
        b."ПримерСоставногоТипа",
        b."ПримерСоставногоТипа_ТипЗначения",
        now() AS dt_create
    FROM odins."FACT_Продажи" b
        INNER JOIN "tmp_FACT_Продажи" ll ON b.ods_id = ll.ods_id;


    DELETE FROM odins."FACT_Продажи_Товары_history" WHERE dwh_session_id = par_dwh_session_id;

    INSERT INTO odins."FACT_Продажи_Товары_history"(
        nkey,
        dwh_session_id,
        "FACT_ПродажиRefID",
        "Доставка",
        "Товар",
        "Колличество",
        "Цена",
        dt_create
    )
    SELECT
        b.nkey,
        par_dwh_session_id AS dwh_session_id,
        b."FACT_ПродажиRefID",
        b."Доставка",
        b."Товар",
        b."Колличество",
        b."Цена",
        now() AS dt_create
    FROM odins."FACT_Продажи_Товары" b
        INNER JOIN "tmp_FACT_Продажи" ll ON b."FACT_ПродажиRefID" = ll."RefID";


    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := par_rowcount + var_rowcount;

    IF var_rowcount > 0 THEN
        INSERT INTO dwh_processing_details( dwh_session_id, schema_name, table_name, row_count)
        SELECT par_dwh_session_id, 'odins', 'FACT_Продажи_Товары',var_rowcount;
    END IF;

    COMMIT;

   -- Deleted and create session
    IF par_rowcount > 0 THEN
        -- Delete star: odins.DIM_Валюты
        DELETE FROM odins."DIM_Валюты" AS b
        USING "tmp_DIM_Валюты" AS ll
        WHERE b.ods_id = ll.ods_id;
            -- Delete child: odins.DIM_Валюты.Представления
            DELETE FROM odins."DIM_Валюты_Представления" AS b
            USING "tmp_DIM_Валюты" AS ll
            WHERE b."DIM_ВалютыRefID" = ll."RefID";
        -- Delete star: odins.DIM_Клиенты
        DELETE FROM odins."DIM_Клиенты" AS b
        USING "tmp_DIM_Клиенты" AS ll
        WHERE b.ods_id = ll.ods_id;
        -- Delete star: odins.DIM_Товары
        DELETE FROM odins."DIM_Товары" AS b
        USING "tmp_DIM_Товары" AS ll
        WHERE b.ods_id = ll.ods_id;
        -- Delete star: odins.FACT_Продажи
        DELETE FROM odins."FACT_Продажи" AS b
        USING "tmp_FACT_Продажи" AS ll
        WHERE b.ods_id = ll.ods_id;
            -- Delete child: odins.FACT_Продажи.Товары
            DELETE FROM odins."FACT_Продажи_Товары" AS b
            USING "tmp_FACT_Продажи" AS ll
            WHERE b."FACT_ПродажиRefID" = ll."RefID";
        CALL public."dwh_SaveSessionState" (par_dwh_session_id::bigint, 1::smallint, 2::smallint, null) ;
    END IF;

    SELECT create_session INTO par_create_session FROM dwh_session WHERE dwh_session_id = par_dwh_session_id;
END;

$BODY$
LANGUAGE plpgsql;
