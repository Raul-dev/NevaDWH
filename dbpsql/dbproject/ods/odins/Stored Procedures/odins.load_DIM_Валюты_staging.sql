do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_DIM_Валюты_staging"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_DIM_Валюты_staging" (
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

  UPDATE "odins"."DIM_Валюты" AS org SET
    "RefID" = src."RefID",
    "DeletionMark" = src."DeletionMark",
    "Code" = src."Code",
    "Description" = src."Description",
    "ЗагружаетсяИзИнтернета" = src."ЗагружаетсяИзИнтернета",
    "НаименованиеПолное" = src."НаименованиеПолное",
    "Наценка" = src."Наценка",
    "ОсновнаяВалюта" = src."ОсновнаяВалюта",
    "ПараметрыПрописи" = src."ПараметрыПрописи",
    "ФормулаРасчетаКурса" = src."ФормулаРасчетаКурса",
    "СпособУстановкиКурса" = src."СпособУстановкиКурса",
    updated_at = var_updatedate
  FROM staging."DIM_Валюты" AS src
  WHERE org."nkey" = src."nkey";

  INSERT INTO "odins"."DIM_Валюты" (
    "nkey",
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
    updated_at
  )
  SELECT
    src."nkey",
    src."RefID",
    src."DeletionMark",
    src."Code",
    src."Description",
    src."ЗагружаетсяИзИнтернета",
    src."НаименованиеПолное",
    src."Наценка",
    src."ОсновнаяВалюта",
    src."ПараметрыПрописи",
    src."ФормулаРасчетаКурса",
    src."СпособУстановкиКурса",
    src.updated_at
  FROM staging."DIM_Валюты" AS src
  LEFT JOIN "odins"."DIM_Валюты" AS org ON org."nkey" = src."nkey"
  WHERE org."RefID" IS NULL;

  /* Sub tables (tabular sections) */
  DELETE FROM "odins"."DIM_Валюты_Представления" AS trg
  USING staging."DIM_Валюты" AS tmp
  WHERE
    trg."DIM_ВалютыRefID" = tmp."RefID";

  INSERT INTO "odins"."DIM_Валюты_Представления" (
    "nkey",
    "DIM_ВалютыRefID",
    "КодЯзыка",
    "ПараметрыПрописи",
    updated_at
  )
  SELECT
    CAST(md5(CONVERT(
      (CAST(tmp."RefID" AS varchar(36)) || '|' || COALESCE(CAST(line_ord AS varchar), '0'))
      ::bytea, 'UTF8', 'UHC')) AS uuid) AS "nkey",
    tmp."RefID" AS "DIM_ВалютыRefID",
    CAST((xpath('//*[local-name()="КодЯзыка"]/text()', line_xml))[1]::text AS varchar(10)) AS "КодЯзыка",
    CAST((xpath('//*[local-name()="ПараметрыПрописи"]/text()', line_xml))[1]::text AS varchar(200)) AS "ПараметрыПрописи",
    var_updatedate AS updated_at
  FROM staging."DIM_Валюты" AS tmp
  CROSS JOIN LATERAL unnest(xpath('/*[local-name()="rows"]/*', tmp."DIM_Валюты_Представления")) WITH ORDINALITY AS line(line_xml, line_ord)
  WHERE tmp."DIM_Валюты_Представления" IS NOT NULL;

  GET DIAGNOSTICS var_rowcount = ROW_COUNT;
  par_rowcount := var_rowcount;
END;

$BODY$
LANGUAGE plpgsql;
