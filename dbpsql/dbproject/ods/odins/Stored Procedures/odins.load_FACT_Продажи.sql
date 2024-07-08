do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_FACT_Продажи"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_FACT_Продажи" (
    par_session_id in bigint DEFAULT NULL, 
    par_rowcount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_rowcount integer;
    var_xmlns text ARRAY;
BEGIN

    SELECT ARRAY[ARRAY['nva', 'http://v8.1c.ru/8.1/data/enterprise/current-config'], ARRAY['xsi', 'http://www.w3.org/2001/XMLSchema-instance'], ARRAY['xs', 'http://www.w3.org/2001/XMLSchema']] into var_xmlns;

    DROP TABLE IF EXISTS "FACT_Продажи_tmp1";
    CREATE TEMPORARY TABLE "FACT_Продажи_tmp1" (
        "buffer_id" int,
        "RefID" uuid
    );

    INSERT INTO "FACT_Продажи_tmp1" (buffer_id, "RefID")
    SELECT MAX(buffer_id) AS buffer_id,
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) ref
    FROM "odins"."FACT_Продажи_buffer" b
    WHERE b."is_error" = false
    GROUP BY CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid);
    
    GET DIAGNOSTICS var_rowcount = ROW_COUNT;
    par_rowcount := var_rowcount;

    IF var_rowcount = 0 THEN
        RETURN;
    END IF;

    DROP TABLE IF EXISTS "FACT_Продажи_tmp2";
    CREATE TEMPORARY TABLE "FACT_Продажи_tmp2" (
        "nkey" uuid,
        "FACT_Продажи_Товары"  xml,
        "RefID" uuid,
        "DeletionMark" boolean,
        "Number" integer,
        "Posted" boolean,
        "Date" timestamp,
        "ДатаОтгрузки" timestamp,
        "Клиент" varchar(36),
        "ТипДоставки" varchar(500),
        "ПримерСоставногоТипа" varchar(36),
        "ПримерСоставногоТипа_ТипЗначения" varchar(128),
        "dt_update" timestamp without time zone 
    );

    INSERT INTO "FACT_Продажи_tmp2"
     (
    SELECT
        CAST(md5(CONVERT(
                CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Ref/text()', msg::xml, var_xmlns ))[1] as VARCHAR)                
                ::bytea,'UTF8','UHC')) AS UUID) AS "nkey",

        (xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:FACT_Продажи.Товары/text()', msg::xml, var_xmlns ))[1]::xml  AS "FACT_Продажи_Товары",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid)  AS "RefID",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:DeletionMark/text()', msg::xml, var_xmlns ))[1]::text as boolean)  AS "DeletionMark",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Number/text()', msg::xml, var_xmlns ))[1]::text as integer)  AS "Number",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Posted/text()', msg::xml, var_xmlns ))[1]::text as boolean)  AS "Posted",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Date/text()', msg::xml, var_xmlns ))[1]::text as timestamp)  AS "Date",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:ДатаОтгрузки/text()', msg::xml, var_xmlns ))[1]::text as timestamp)  AS "ДатаОтгрузки",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Клиент/text()', msg::xml, var_xmlns ))[1]::text as varchar(36))  AS "Клиент",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:ТипДоставки/text()', msg::xml, var_xmlns ))[1]::text as varchar(500))  AS "ТипДоставки",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:ПримерСоставногоТипа/text()', msg::xml, var_xmlns ))[1]::text as varchar(36))  AS "ПримерСоставногоТипа",
        CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:ПримерСоставногоТипа/@xsi:type', msg::xml, var_xmlns ))[1]::text as varchar(128))  AS "ПримерСоставногоТипа_ТипЗначения",
        CAST(now() as timestamp without time zone) 
    FROM "odins"."FACT_Продажи_buffer" AS b
    WHERE b."is_error" = false AND EXISTS (SELECT 1 FROM "FACT_Продажи_tmp1" AS t WHERE CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) = t."RefID" AND b.buffer_id = t.buffer_id )
    );

    UPDATE "odins"."FACT_Продажи" AS org SET
        "nkey" = src."nkey",
        "RefID" = src."RefID",
        "DeletionMark" = src."DeletionMark",
        "Number" = src."Number",
        "Posted" = src."Posted",
        "Date" = src."Date",
        "ДатаОтгрузки" = src."ДатаОтгрузки",
        "Клиент" = src."Клиент",
        "ТипДоставки" = src."ТипДоставки",
        "ПримерСоставногоТипа" = src."ПримерСоставногоТипа",
        "ПримерСоставногоТипа_ТипЗначения" = src."ПримерСоставногоТипа_ТипЗначения",
        dt_update = now()
    FROM "FACT_Продажи_tmp2" AS src 
    WHERE org."nkey" = src."nkey" ;
    INSERT INTO "odins"."FACT_Продажи" (
        "nkey" ,
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
        dt_update
    )
    SELECT 
    
        src."nkey" ,
        src."RefID",
        src."DeletionMark",
        src."Number",
        src."Posted",
        src."Date",
        src."ДатаОтгрузки",
        src."Клиент",
        src."ТипДоставки",
        src."ПримерСоставногоТипа",
        src."ПримерСоставногоТипа_ТипЗначения",
        src."dt_update"
     FROM "FACT_Продажи_tmp2" AS src 
        LEFT JOIN "odins"."FACT_Продажи" AS org ON org."nkey" = src."nkey" 
     WHERE org."RefID" IS NULL ;
     

    DELETE FROM "odins"."FACT_Продажи_buffer" AS b 
    WHERE EXISTS (SELECT 1 FROM "FACT_Продажи_tmp1" AS t WHERE CAST((xpath('/nva:Data/nva:Реквизиты/nva:DocumentObject.Продажи/nva:Ref/text()', msg::xml, var_xmlns ))[1]::text as uuid) = t."RefID" AND b.buffer_id <= t.buffer_id );

END;

$BODY$
LANGUAGE plpgsql;
