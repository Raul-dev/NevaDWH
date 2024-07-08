do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_DIM_Клиенты"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_DIM_Клиенты" (
    par_session_id in bigint DEFAULT NULL, 
    par_rowcount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_rowcount integer;
    var_xmlns text ARRAY;
BEGIN

    SELECT ARRAY[ARRAY['nva', 'http://v8.1c.ru/8.1/data/enterprise/current-config'], ARRAY['xsi', 'http://www.w3.org/2001/XMLSchema-instance'], ARRAY['xs', 'http://www.w3.org/2001/XMLSchema']] into var_xmlns;

    DROP TABLE IF EXISTS "DIM_Клиенты_tmp1";
    CREATE TEMPORARY TABLE "DIM_Клиенты_tmp1" (
        "buffer_id" int,
        "RefID" uuid
    );

    INSERT INTO "DIM_Клиенты_tmp1" (buffer_id, "RefID")
    SELECT MAX(buffer_id) AS buffer_id,
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) ref
    FROM "odins"."DIM_Клиенты_buffer" b
    WHERE b."is_error" = false
    GROUP BY CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid);
    
    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := var_rowcount;

    IF var_rowcount = 0 THEN
        RETURN;
    END IF;

    DROP TABLE IF EXISTS "DIM_Клиенты_tmp2";
    CREATE TEMPORARY TABLE "DIM_Клиенты_tmp2" (
        "nkey" uuid,
        "RefID" uuid,
        "DeletionMark" boolean,
        "Code" varchar(128),
        "Description" varchar(128),
        "Контакт" varchar(500),
        "dt_update" timestamp without time zone 
    );

    INSERT INTO "DIM_Клиенты_tmp2"
     (
    SELECT
        CAST(md5(CONVERT(
                CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1] as VARCHAR)                
                ::bytea,'UTF8','UHC')) AS UUID) AS "nkey",

        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid)  AS "RefID",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:DeletionMark/text()', msg::xml, var_xmlns ))[1]::text as boolean)  AS "DeletionMark",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Code/text()', msg::xml, var_xmlns ))[1]::text as varchar(128))  AS "Code",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Description/text()', msg::xml, var_xmlns ))[1]::text as varchar(128))  AS "Description",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Контакт/text()', msg::xml, var_xmlns ))[1]::text as varchar(500))  AS "Контакт",
        CAST(now() as timestamp without time zone) 
    FROM "odins"."DIM_Клиенты_buffer" AS b
    WHERE b."is_error" = false AND EXISTS (SELECT 1 FROM "DIM_Клиенты_tmp1" AS t WHERE CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) = t."RefID" AND b.buffer_id = t.buffer_id )
    );

    UPDATE "odins"."DIM_Клиенты" AS org SET
        "nkey" = src."nkey",
        "RefID" = src."RefID",
        "DeletionMark" = src."DeletionMark",
        "Code" = src."Code",
        "Description" = src."Description",
        "Контакт" = src."Контакт",
        dt_update = now()
    FROM "DIM_Клиенты_tmp2" AS src 
    WHERE org."nkey" = src."nkey" ;
    INSERT INTO "odins"."DIM_Клиенты" (
        "nkey" ,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Контакт",
        dt_update
    )
    SELECT 
    
        src."nkey" ,
        src."RefID",
        src."DeletionMark",
        src."Code",
        src."Description",
        src."Контакт",
        src."dt_update"
     FROM "DIM_Клиенты_tmp2" AS src 
        LEFT JOIN "odins"."DIM_Клиенты" AS org ON org."nkey" = src."nkey" 
     WHERE org."RefID" IS NULL ;
     

    DELETE FROM "odins"."DIM_Клиенты_buffer" AS b 
    WHERE EXISTS (SELECT 1 FROM "DIM_Клиенты_tmp1" AS t WHERE CAST((xpath('/nva:Data/nva:Реквизиты/nva:CatalogObject.Клиенты/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) = t."RefID" AND b.buffer_id <= t.buffer_id );

END;

$BODY$
LANGUAGE plpgsql;
