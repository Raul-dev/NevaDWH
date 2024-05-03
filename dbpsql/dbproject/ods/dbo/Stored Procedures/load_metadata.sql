do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "load_metadata"';
END;
$$;
-- CALL load_metadata(NULL,NULL);
CREATE OR REPLACE PROCEDURE "load_metadata" (
    par_session_id IN BIGINT  DEFAULT NULL, 
    par_rowcount inout INT DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
BEGIN

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
    WHERE 
        trg.buffer_id = tmp.buffer_id;

END;

$BODY$
LANGUAGE plpgsql;
