do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_DIM_Товары_staging"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_DIM_Товары_staging" (
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

  UPDATE "odins"."DIM_Товары" AS org SET
    "RefID" = src."RefID",
    "DeletionMark" = src."DeletionMark",
    "Code" = src."Code",
    "Description" = src."Description",
    "Описание" = src."Описание",
    updated_at = var_updatedate
  FROM staging."DIM_Товары" AS src
  WHERE org."nkey" = src."nkey";

  INSERT INTO "odins"."DIM_Товары" (
    "nkey",
    "RefID",
    "DeletionMark",
    "Code",
    "Description",
    "Описание",
    updated_at
  )
  SELECT
    src."nkey",
    src."RefID",
    src."DeletionMark",
    src."Code",
    src."Description",
    src."Описание",
    src.updated_at
  FROM staging."DIM_Товары" AS src
  LEFT JOIN "odins"."DIM_Товары" AS org ON org."nkey" = src."nkey"
  WHERE org."RefID" IS NULL;

  /* Sub tables (tabular sections) */
  GET DIAGNOSTICS var_rowcount = ROW_COUNT;
  par_rowcount := var_rowcount;
END;

$BODY$
LANGUAGE plpgsql;
