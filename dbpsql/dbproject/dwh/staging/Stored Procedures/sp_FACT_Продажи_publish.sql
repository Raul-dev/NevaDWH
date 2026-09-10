do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_FACT_Продажи_p"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_FACT_Продажи_p" (
  par_session_id in int DEFAULT NULL, 
  par_RowCount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
  var_RowCount INTEGER;
BEGIN

  UPDATE target."FACT_Продажи" AS trg SET
    session_id = stg.session_id,
    start_date = stg.start_date,
    end_date = stg.end_date,
    session_id_update = stg.session_id_update,
    updated_at = stg.updated_at,
    "RefID" = stg."RefID",
    "DeletionMark" = stg."DeletionMark",
    "Number" = stg."Number",
    "Posted" = stg."Posted",
    "Date" = stg."Date",
    "DateID" = stg."DateID",
    "ДатаОтгрузки" = stg."ДатаОтгрузки",
    "ДатаОтгрузкиID" = stg."ДатаОтгрузкиID",
    "Клиент" = stg."Клиент",
    "ТипДоставки" = stg."ТипДоставки",
    "ПримерСоставногоТипа" = stg."ПримерСоставногоТипа",
    "ПримерСоставногоТипа_ТипЗначения" = stg."ПримерСоставногоТипа_ТипЗначения"
  FROM staging."FACT_Продажи" stg
  WHERE stg.id = trg.id;

  INSERT INTO target."FACT_Продажи" (
    id,
    session_id,
    source_name,
    nkey,
    vkey,
    start_date,
    end_date,
    session_id_update,
    updated_at,
    created_at,
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
    "ПримерСоставногоТипа_ТипЗначения"
  )
  SELECT
    id,
    session_id,
    source_name,
    nkey,
    vkey,
    start_date,
    end_date,
    session_id_update,
    updated_at,
    now() as created_at,
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
    "ПримерСоставногоТипа_ТипЗначения"
  FROM staging."FACT_Продажи"
  WHERE staging_id = id;
  UPDATE target."FACT_Продажи_Товары" AS trg SET
    session_id = stg.session_id,
    start_date = stg.start_date,
    end_date = stg.end_date,
    session_id_update = stg.session_id_update,
    updated_at = stg.updated_at,
    "FACT_ПродажиRefID" = stg."FACT_ПродажиRefID",
    "Доставка" = stg."Доставка",
    "Товар" = stg."Товар",
    "Колличество" = stg."Колличество",
    "Цена" = stg."Цена"
  FROM staging."FACT_Продажи_Товары" stg
  WHERE stg.id = trg.id;

  INSERT INTO target."FACT_Продажи_Товары" (
    id,
    session_id,
    source_name,
    nkey,
    vkey,
    start_date,
    end_date,
    session_id_update,
    updated_at,
    created_at,
    "FACT_ПродажиRefID",
    "Доставка",
    "Товар",
    "Колличество",
    "Цена"
  )
  SELECT
    id,
    session_id,
    source_name,
    nkey,
    vkey,
    start_date,
    end_date,
    session_id_update,
    updated_at,
    now() as created_at,
    "FACT_ПродажиRefID",
    "Доставка",
    "Товар",
    "Колличество",
    "Цена"
  FROM staging."FACT_Продажи_Товары"
  WHERE staging_id = id;

END;

$BODY$
LANGUAGE plpgsql;
