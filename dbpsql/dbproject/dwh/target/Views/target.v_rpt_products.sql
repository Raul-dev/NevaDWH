do
$$
BEGIN
  RAISE NOTICE 'Create view target.v_rpt_products';
END;
$$;

DROP VIEW IF EXISTS target.v_rpt_products;

CREATE VIEW target.v_rpt_products
AS
SELECT
  p.id,
  p."RefID",
  p."Code",
  p."Description",
  p."Описание",
  p."DeletionMark",
  COALESCE(sales."SaleCount", 0) AS "SaleCount",
  COALESCE(sales."Qty", 0) AS "Qty",
  COALESCE(sales."Amount", 0) AS "Amount",
  sales."FirstSaleDate",
  sales."LastSaleDate"
FROM target."DIM_Товары" AS p
LEFT JOIN LATERAL (
  SELECT
    COUNT(DISTINCT s."RefID")::bigint AS "SaleCount",
    SUM(COALESCE(l."Колличество", 0)) AS "Qty",
    SUM(COALESCE(l."Колличество", 0) * COALESCE(l."Цена", 0)) AS "Amount",
    MIN(s."Date"::date) AS "FirstSaleDate",
    MAX(s."Date"::date) AS "LastSaleDate"
  FROM target."FACT_Продажи_Товары" AS l
  INNER JOIN target."FACT_Продажи" AS s
    ON s."RefID" = l."FACT_ПродажиRefID"
    AND s.end_date = mq."fn_GetMaxDate"()
    AND COALESCE(s."DeletionMark", false) = false
  WHERE l.end_date = mq."fn_GetMaxDate"()
    AND p."RefID"::varchar(36) = l."Товар"
) AS sales ON true
WHERE p.end_date = mq."fn_GetMaxDate"()
  AND COALESCE(p."DeletionMark", false) = false;
