do
$$
BEGIN
  RAISE NOTICE 'Create view target.v_rpt_sales_products';
END;
$$;

DROP VIEW IF EXISTS target.v_rpt_sales_products;

CREATE VIEW target.v_rpt_sales_products
AS
SELECT
  s.id AS "SaleId",
  s."RefID" AS "SaleRefID",
  s."Number" AS "SaleNumber",
  s."Date" AS "SaleDateTime",
  s."DateID",
  s."Date"::date AS "SaleDate",
  EXTRACT(YEAR FROM s."Date")::smallint AS "CalendarYear",
  EXTRACT(QUARTER FROM s."Date")::smallint AS "CalendarQuarter",
  EXTRACT(MONTH FROM s."Date")::smallint AS "MonthNumberOfYear",
  s."Клиент" AS "ClientRef",
  c."Code" AS "ClientCode",
  c."Description" AS "ClientName",
  s."ТипДоставки",
  l.id AS "LineId",
  l."Товар" AS "ProductRef",
  p."Code" AS "ProductCode",
  p."Description" AS "ProductName",
  p."Описание" AS "ProductDescription",
  l."Доставка",
  l."Колличество" AS "Qty",
  l."Цена" AS "Price",
  COALESCE(l."Колличество", 0) * COALESCE(l."Цена", 0) AS "Amount"
FROM target."FACT_Продажи" AS s
INNER JOIN target."FACT_Продажи_Товары" AS l
  ON l."FACT_ПродажиRefID" = s."RefID"
  AND l.end_date = mq."fn_GetMaxDate"()
LEFT JOIN target."DIM_Клиенты" AS c
  ON c.end_date = mq."fn_GetMaxDate"()
  AND COALESCE(c."DeletionMark", false) = false
  AND c."RefID"::varchar(36) = s."Клиент"
LEFT JOIN target."DIM_Товары" AS p
  ON p.end_date = mq."fn_GetMaxDate"()
  AND COALESCE(p."DeletionMark", false) = false
  AND p."RefID"::varchar(36) = l."Товар"
WHERE s.end_date = mq."fn_GetMaxDate"()
  AND COALESCE(s."DeletionMark", false) = false;
