do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_FACT_Продажи_staging"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_FACT_Продажи_staging" (
  par_session_id in bigint DEFAULT NULL,
  par_rowcount inout int DEFAULT NULL
)
AS $BODY$
DECLARE
  var_rowcount int;
  var_updatedate timestamp without time zone;
  var_xmlns text ARRAY;
BEGIN
  SELECT now() INTO var_updatedate;
  SELECT ARRAY[ARRAY['nva', 'http://v8.1c.ru/8.1/data/enterprise/current-config'], ARRAY['xsi', 'http://www.w3.org/2001/XMLSchema-instance'], ARRAY['xs', 'http://www.w3.org/2001/XMLSchema']] INTO var_xmlns;

  UPDATE "odins"."FACT_Продажи" AS org SET
    "RefID" = src."RefID",
    "DeletionMark" = src."DeletionMark",
    "Number" = src."Number",
    "Posted" = src."Posted",
    "Date" = src."Date",
    "DateID" = src."DateID",
    "ДатаОтгрузки" = src."ДатаОтгрузки",
    "ДатаОтгрузкиID" = src."ДатаОтгрузкиID",
    "Клиент" = src."Клиент",
    "ТипДоставки" = src."ТипДоставки",
    "ПримерСоставногоТипа" = src."ПримерСоставногоТипа",
    "ПримерСоставногоТипа_ТипЗначения" = src."ПримерСоставногоТипа_ТипЗначения",
    updated_at = var_updatedate
  FROM staging."FACT_Продажи" AS src
  WHERE org."nkey" = src."nkey";

  INSERT INTO "odins"."FACT_Продажи" (
    "nkey",
    "RefID",
    "DeletionMark",
    "Number",
    "Posted",
    "Date",
    "DateID",
    "ДатаОтгрузки",
    "ДатаОтгрузкиID",
    "Клиент",
    "ТипДоставки",
    "ПримерСоставногоТипа",
    "ПримерСоставногоТипа_ТипЗначения",
    updated_at
  )
  SELECT
    src."nkey",
    src."RefID",
    src."DeletionMark",
    src."Number",
    src."Posted",
    src."Date",
    src."DateID",
    src."ДатаОтгрузки",
    src."ДатаОтгрузкиID",
    src."Клиент",
    src."ТипДоставки",
    src."ПримерСоставногоТипа",
    src."ПримерСоставногоТипа_ТипЗначения",
    src.updated_at
  FROM staging."FACT_Продажи" AS src
  LEFT JOIN "odins"."FACT_Продажи" AS org ON org."nkey" = src."nkey"
  WHERE org."RefID" IS NULL;

  /* Sub tables (tabular sections) */
  DELETE FROM "odins"."FACT_Продажи_Товары" AS trg
  USING staging."FACT_Продажи" AS tmp
  WHERE
    trg."FACT_ПродажиRefID" = tmp."RefID";

  INSERT INTO "odins"."FACT_Продажи_Товары" (
    "nkey",
    "FACT_ПродажиRefID",
    "Доставка",
    "Товар",
    "Колличество",
    "Цена",
    updated_at
  )
  SELECT
    CAST(md5(CONVERT(
      (CAST(tmp."RefID" AS varchar(36)) || '|' || COALESCE(CAST(line_ord AS varchar), '0'))
      ::bytea, 'UTF8', 'UHC')) AS uuid) AS "nkey",
    tmp."RefID" AS "FACT_ПродажиRefID",
    CAST((xpath('//*[local-name()="Доставка"]/text()', line_xml))[1]::text AS boolean) AS "Доставка",
    CAST((xpath('//*[local-name()="Товар"]/text()', line_xml))[1]::text AS varchar(36)) AS "Товар",
    CAST((xpath('//*[local-name()="Колличество"]/text()', line_xml))[1]::text AS decimal(12, 0)) AS "Колличество",
    CAST((xpath('//*[local-name()="Цена"]/text()', line_xml))[1]::text AS decimal(16, 4)) AS "Цена",
    var_updatedate AS updated_at
  FROM staging."FACT_Продажи" AS tmp
  CROSS JOIN LATERAL unnest(xpath('/*[local-name()="rows"]/*', tmp."FACT_Продажи_Товары")) WITH ORDINALITY AS line(line_xml, line_ord)
  WHERE tmp."FACT_Продажи_Товары" IS NOT NULL;

  GET DIAGNOSTICS var_rowcount = ROW_COUNT;
  par_rowcount := var_rowcount;
END;

$BODY$
LANGUAGE plpgsql;
