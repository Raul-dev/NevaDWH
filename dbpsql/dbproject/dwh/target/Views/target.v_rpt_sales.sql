do
$$
BEGIN
  RAISE NOTICE 'Create view target.v_rpt_sales';
END;
$$;

DROP VIEW IF EXISTS target.v_rpt_sales;

CREATE VIEW target.v_rpt_sales
AS
SELECT
  s.id,
  s."RefID",
  s."Number",
  s."Posted",
  s."Date",
  s."DateID",
  s."Date"::date AS "SaleDate",
  EXTRACT(YEAR FROM s."Date")::smallint AS "CalendarYear",
  EXTRACT(QUARTER FROM s."Date")::smallint AS "CalendarQuarter",
  EXTRACT(MONTH FROM s."Date")::smallint AS "MonthNumberOfYear",
  TO_CHAR(s."Date", 'Mon') AS "MonthName",
  s."ДатаОтгрузки",
  s."ДатаОтгрузкиID",
  s."Клиент" AS "ClientRef",
  c."Code" AS "ClientCode",
  c."Description" AS "ClientName",
  s."ТипДоставки",
  COALESCE(lines."LineCount", 0) AS "LineCount",
  COALESCE(lines."Qty", 0) AS "Qty",
  COALESCE(lines."Amount", 0) AS "Amount"
FROM target."FACT_Продажи" AS s
LEFT JOIN target."DIM_Клиенты" AS c
  ON c.end_date = mq."fn_GetMaxDate"()
  AND COALESCE(c."DeletionMark", false) = false
  AND c."RefID"::varchar(36) = s."Клиент"
LEFT JOIN LATERAL (
  SELECT
    COUNT(*)::bigint AS "LineCount",
    SUM(COALESCE(l."Колличество", 0)) AS "Qty",
    SUM(COALESCE(l."Колличество", 0) * COALESCE(l."Цена", 0)) AS "Amount"
  FROM target."FACT_Продажи_Товары" AS l
  WHERE l.end_date = mq."fn_GetMaxDate"()
    AND l."FACT_ПродажиRefID" = s."RefID"
) AS lines ON true
WHERE s.end_date = mq."fn_GetMaxDate"()
  AND COALESCE(s."DeletionMark", false) = false;
