CREATE VIEW [target].[v_rpt_products]
AS
SELECT
  p.[id],
  p.[RefID],
  p.[Code],
  p.[Description],
  p.[Описание],
  p.[DeletionMark],
  ISNULL(sales.[SaleCount], 0) AS [SaleCount],
  ISNULL(sales.[Qty], 0) AS [Qty],
  ISNULL(sales.[Amount], 0) AS [Amount],
  sales.[FirstSaleDate],
  sales.[LastSaleDate]
FROM [target].[DIM_Товары] AS p
OUTER APPLY (
  SELECT
    COUNT_BIG(DISTINCT s.[RefID]) AS [SaleCount],
    SUM(ISNULL(l.[Колличество], 0)) AS [Qty],
    SUM(ISNULL(l.[Колличество], 0) * ISNULL(l.[Цена], 0)) AS [Amount],
    MIN(d.[FullDateAlternateKey]) AS [FirstSaleDate],
    MAX(d.[FullDateAlternateKey]) AS [LastSaleDate]
  FROM [target].[FACT_Продажи.Товары] AS l
  INNER JOIN [target].[FACT_Продажи] AS s
    ON s.[RefID] = l.[FACT_ПродажиRefID]
    AND s.[end_date] = [mq].[fn_GetMaxDate]()
    AND ISNULL(s.[DeletionMark], 0) = 0
  LEFT JOIN [target].[DIM_Date] AS d
    ON d.[DateID] = s.[DateID]
  WHERE l.[end_date] = [mq].[fn_GetMaxDate]()
    AND CAST(p.[RefID] AS varchar(36)) = l.[Товар]
) AS sales
WHERE p.[end_date] = [mq].[fn_GetMaxDate]()
  AND ISNULL(p.[DeletionMark], 0) = 0;
GO
