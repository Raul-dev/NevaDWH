do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_DIM_Товары"';
END;
$$;

-- CALL odins."load_DIM_Товары"(NULL::bigint, 1::smallint, NULL::integer, NULL::varchar(4000))
CREATE OR REPLACE PROCEDURE odins."load_DIM_Товары" (
    IN par_session_id bigint DEFAULT NULL,
	IN par_buffer_history_mode smallint DEFAULT 2::smallint,  -- 0 - Do not delete the buffering history.
                                                              -- 1 - Delete the buffering history.
                                                              -- 2 - Keep the buffering history for 10 days.
                                                              -- 3 - Keep the buffering history for a month.
	INOUT par_rowcount integer DEFAULT NULL::integer,
	INOUT par_errmessage varchar(4000) DEFAULT NULL::varchar(4000)
)
AS $BODY$
DECLARE
    var_rowcount integer;
    var_xmlns text ARRAY;
    var_mindate timestamp without time zone;
	var_updatedate timestamp without time zone;
	var_bufferhistorydays int;
	var_err_session_id bigint;
    var_buffer_history_mode smallint;
BEGIN
    var_buffer_history_mode := CASE WHEN par_buffer_history_mode IS NULL OR par_buffer_history_mode > 2 THEN 2 ELSE par_buffer_history_mode END;
    SELECT now() INTO var_updatedate;
	SELECT to_date('19000101', 'YYYYMMDD') INTO var_mindate;
	SELECT (CASE WHEN (par_buffer_history_mode = 2) THEN 10 ELSE 30 END) INTO var_bufferhistorydays;

    SELECT ARRAY[ARRAY['nva', 'http://v8.1c.ru/8.1/data/enterprise/current-config'], ARRAY['xsi', 'http://www.w3.org/2001/XMLSchema-instance'], ARRAY['xs', 'http://www.w3.org/2001/XMLSchema']] into var_xmlns;

    DROP TABLE IF EXISTS "DIM_Товары_lock";
    CREATE TEMPORARY TABLE "DIM_Товары_lock" (
        "buffer_id" int,
        "RefID" uuid
    );

    DROP TABLE IF EXISTS "DIM_Товары_tmp1";
    CREATE TEMPORARY TABLE "DIM_Товары_tmp1" (
        "buffer_id" int,
        "RefID" uuid
    );

    INSERT INTO "DIM_Товары_lock" (buffer_id, "RefID")
    SELECT buffer_id AS buffer_id,
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) ref
    FROM "odins"."DIM_Товары_buffer" b
    WHERE b.dt_update = var_mindate;

    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := var_rowcount;

    IF var_rowcount = 0 THEN
        RETURN;
    END IF;

    BEGIN
		INSERT INTO "DIM_Товары_tmp1" (buffer_id, "RefID")
		SELECT MAX(buffer_id) AS buffer_id,
			"RefID"
		FROM "DIM_Товары_lock" b
		GROUP BY "RefID";

        GET DIAGNOSTICS var_rowcount = ROW_COUNT;
        par_rowcount := var_rowcount;

        DROP TABLE IF EXISTS "DIM_Товары_tmp2";
        CREATE TEMPORARY TABLE "DIM_Товары_tmp2" (
            "nkey" uuid,
            "RefID" uuid,
            "DeletionMark" boolean,
            "Code" varchar(128),
            "Description" varchar(128),
            "Описание" varchar(255),
            "dt_update" timestamp without time zone 
        );

        INSERT INTO "DIM_Товары_tmp2"
        (
        SELECT
            CAST(md5(CONVERT(
                    CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:Ref/text()', msg::xml, var_xmlns ))[1] as VARCHAR)                    
                    ::bytea,'UTF8','UHC')) AS UUID) AS "nkey",

            CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid)  AS "RefID",
            CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:DeletionMark/text()', msg::xml, var_xmlns ))[1]::text as boolean)  AS "DeletionMark",
            CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:Code/text()', msg::xml, var_xmlns ))[1]::text as varchar(128))  AS "Code",
            CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:Description/text()', msg::xml, var_xmlns ))[1]::text as varchar(128))  AS "Description",
            CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:Описание/text()', msg::xml, var_xmlns ))[1]::text as varchar(255))  AS "Описание",
            CAST(now() as timestamp without time zone) 
        FROM "odins"."DIM_Товары_buffer" AS b
        WHERE b."is_error" = false AND EXISTS (SELECT 1 FROM "DIM_Товары_tmp1" AS t WHERE CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Товары/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) = t."RefID" AND b.buffer_id = t.buffer_id )
        );

        UPDATE "odins"."DIM_Товары" AS org SET
            "nkey" = src."nkey",
            "RefID" = src."RefID",
            "DeletionMark" = src."DeletionMark",
            "Code" = src."Code",
            "Description" = src."Description",
            "Описание" = src."Описание",
            dt_update = var_updatedate
        FROM "DIM_Товары_tmp2" AS src 
        WHERE org."nkey" = src."nkey" ;

        INSERT INTO "odins"."DIM_Товары" (
            "nkey" ,
            "RefID",
            "DeletionMark",
            "Code",
            "Description",
            "Описание",
            dt_update
        )
        SELECT 
            src."nkey" ,
            src."RefID",
            src."DeletionMark",
            src."Code",
            src."Description",
            src."Описание",
            src."dt_update"
         FROM "DIM_Товары_tmp2" AS src 
            LEFT JOIN "odins"."DIM_Товары" AS org ON org."nkey" = src."nkey" 
         WHERE org."RefID" IS NULL ;


		-- Clear buffer table
		IF var_buffer_history_mode = 1 AND NOT EXISTS (SELECT 1 FROM "odins"."DIM_Товары_buffer" WHERE is_error = true) THEN

			DELETE FROM "odins"."DIM_Товары_buffer" AS org
				USING "DIM_Товары_lock" AS src
			WHERE org."buffer_id" = src."buffer_id";

		ELSE

			UPDATE "odins"."DIM_Товары_buffer" AS org SET
				dt_update = var_updatedate
			FROM "DIM_Товары_lock" AS src
			WHERE org."buffer_id" = src."buffer_id";

			IF var_buffer_history_mode >= 2 AND NOT EXISTS (SELECT 1 FROM "odins"."DIM_Товары_buffer" WHERE is_error = true) THEN
				DELETE
				FROM "odins"."DIM_Товары_buffer" AS b
				WHERE EXTRACT(DAY FROM var_updatedate::timestamp - dt_update::timestamp) > var_bufferhistorydays;
			END IF;
		END	IF;

	EXCEPTION WHEN OTHERS
	THEN
		GET STACKED DIAGNOSTICS
		par_errmessage = MESSAGE_TEXT;

		SELECT COALESCE(par_session_id, 0) INTO var_err_session_id;
		INSERT INTO session_log (session_id, session_state_id, error_message)
		SELECT var_err_session_id,
			3 AS session_state_id,
			'Table odins.DIM_Товары. Error: ' || par_errmessage AS error_message;

		UPDATE "odins"."DIM_Товары_buffer" AS org SET
			is_error  = true,
			dt_update = var_updatedate
		FROM "DIM_Товары_lock" AS src
		WHERE org."buffer_id" = src."buffer_id";

	END;
END;

$BODY$
LANGUAGE plpgsql;
