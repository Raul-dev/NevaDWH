do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "load_metadata"';
END;
$$;
-- CALL load_metadata(NULL,NULL);
CREATE OR REPLACE PROCEDURE "load_metadata" (
    IN par_session_id bigint DEFAULT NULL::bigint,
    IN par_buffer_history_mode smallint DEFAULT (0)::smallint,
    INOUT par_rowcount integer DEFAULT NULL::integer,
    INOUT par_errmessage character varying DEFAULT NULL::character varying(4000)
)
AS $BODY$
DECLARE
    var_RowCount int;
    var_mindate timestamp without time zone;
    var_updatedate timestamp without time zone;
    var_bufferhistorydays int;
    var_err_session_id bigint;
    var_buffer_history_mode smallint;

BEGIN
    var_buffer_history_mode := CASE WHEN par_buffer_history_mode IS NULL OR par_buffer_history_mode > 2 THEN 2 ELSE par_buffer_history_mode END;
    SELECT now() INTO var_updatedate;
    SELECT now() INTO var_updatedate;
    SELECT to_date('19000101', 'YYYYMMDD') INTO var_mindate;
    SELECT (CASE WHEN (par_buffer_history_mode = 2) THEN 10 ELSE 30 END) INTO var_bufferhistorydays;

    DROP TABLE IF EXISTS "metadata_tmp1";
    CREATE TEMPORARY TABLE "metadata_tmp1" (
        buffer_id int,
        "namespace_ver" varchar(256)
    );
    LOCK TABLE metadata_buffer IN ROW EXCLUSIVE MODE;

    INSERT INTO "metadata_tmp1" (
        SELECT buffer_id,
        CAST(msg as json)->'Реквизиты'->0->>'ПространствоИменСВерсией' AS "namespace_ver"
        FROM "metadata_buffer" b
        WHERE b."is_error" = false FOR UPDATE
    );
    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := var_rowcount;

    IF var_rowcount = 0 THEN
        return;
    END IF;
    BEGIN
        DROP TABLE IF EXISTS "metadata_tmp2";
        CREATE TEMPORARY TABLE "metadata_tmp2" (
            nkey uuid NOT NULL,
            namespace character varying(256) ,
            namespace_ver character varying(256) ,
            msg text ,
            type character varying(128) ,
            dt_create timestamp with time zone NOT NULL,
            CONSTRAINT "PK_metadata" PRIMARY KEY (nkey)
        );

        INSERT INTO "metadata_tmp2" (
        SELECT 
            CAST(md5(CONVERT(
                (CAST(msg as json)->'Реквизиты'->0->>'ПространствоИменСВерсией')
                ::bytea,'UTF8','UHC')) AS UUID) AS  nkey,

            CAST(msg as json)->'Реквизиты'->0->>'ПространствоИменИсходное' AS "namespace",
            CAST(msg as json)->'Реквизиты'->0->>'ПространствоИменСВерсией' AS "namespace_ver",
            msg, 'json' as type, now()
            FROM "metadata_buffer" b
                INNER JOIN (SELECT MAX(buffer_id) AS buffer_id FROM metadata_tmp1 GROUP BY namespace_ver ) t ON b.buffer_id = t.buffer_id
            WHERE b."is_error" = false 
        );

        UPDATE metadata AS t SET
            namespace = b.namespace,
            namespace_ver = b.namespace_ver,
            msg = b.msg,
            type = b.type
         FROM metadata_tmp2 b
         WHERE 
            b.nkey = t.nkey;


        INSERT INTO metadata (
            SELECT b.* FROM metadata_tmp2 b
            WHERE NOT EXISTS (SELECT 1 FROM metadata t WHERE b.nkey = t.nkey )
        );

        DELETE 
        FROM metadata_buffer as trg
        USING metadata_tmp1 AS tmp
        WHERE trg.buffer_id = tmp.buffer_id;

            -- Clear buffer table
        IF var_buffer_history_mode = 1 AND NOT EXISTS (SELECT 1 FROM metadata_buffer WHERE is_error = true) THEN
    
            DELETE FROM metadata_buffer AS org 
                USING "metadata_tmp1" AS src
            WHERE org."buffer_id" = src."buffer_id";
    
        ELSE
            
            UPDATE metadata_buffer AS org SET
                dt_update = var_updatedate
            FROM "metadata_tmp1" AS src 
            WHERE org."buffer_id" = src."buffer_id" ;
        
            IF var_buffer_history_mode >= 2 AND NOT EXISTS (SELECT 1 FROM metadata_buffer WHERE is_error = true) THEN
                DELETE 
                FROM metadata_buffer AS b
                WHERE EXTRACT(DAY FROM  var_updatedate::timestamp - dt_update::timestamp) > var_bufferhistorydays;
            END IF;
        END    IF;

    EXCEPTION WHEN OTHERS -- аналог catch  
    THEN
        GET STACKED DIAGNOSTICS
        par_errmessage = MESSAGE_TEXT;
    
        SELECT COALESCE(par_session_id, 0) INTO var_err_session_id;
        INSERT INTO session_log (session_id, session_state_id, error_message)
        SELECT var_err_session_id,
            3 AS session_state_id,
            'Table metadata_buffer. Error: ' || par_errmessage AS error_message;

        UPDATE metadata_buffer AS org SET
            is_error  = true,
            dt_update = var_updatedate
        FROM "metadata_tmp1" AS src 
        WHERE org."buffer_id" = src."buffer_id" ;
    
    END;
END;

$BODY$
LANGUAGE plpgsql;
