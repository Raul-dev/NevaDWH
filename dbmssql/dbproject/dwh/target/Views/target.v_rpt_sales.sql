CREATE VIEW [target].[v_rpt_sales]
AS
SELECT
  s.[id],
  s.[RefID],
  s.[Number],
  s.[Posted],
  s.[Date],
  s.[DateID],
  d.[FullDateAlternateKey] AS [SaleDate],
  d.[CalendarYear],
  d.[CalendarQuarter],
  d.[MonthNumberOfYear],
  d.[MonthName],
  s.[ДатаОтгрузки],
  s.[ДатаОтгрузкиID],
  s.[Клиент] AS [ClientRef],
  c.[Code] AS [ClientCode],
  c.[Description] AS [ClientName],
  s.[ТипДоставки],
  ISNULL(lines.[LineCount], 0) AS [LineCount],
  ISNULL(lines.[Qty], 0) AS [Qty],
  ISNULL(lines.[Amount], 0) AS [Amount]
FROM [target].[FACT_Продажи] AS s
LEFT JOIN [target].[DIM_Date] AS d
  ON d.[DateID] = s.[DateID]
LEFT JOIN [target].[DIM_Клиенты] AS c
  ON c.[end_date] = [mq].[fn_GetMaxDate]()
  AND c.[DeletionMark] = 0
  AND CAST(c.[RefID] AS varchar(36)) = s.[Клиент]
OUTER APPLY (
  SELECT
    COUNT_BIG(1) AS [LineCount],
    SUM(ISNULL(l.[Колличество], 0)) AS [Qty],
    SUM(ISNULL(l.[Колличество], 0) * ISNULL(l.[Цена], 0)) AS [Amount]
  FROM [target].[FACT_Продажи.Товары] AS l
  WHERE l.[end_date] = [mq].[fn_GetMaxDate]()
    AND l.[FACT_ПродажиRefID] = s.[RefID]
) AS lines
WHERE s.[end_date] = [mq].[fn_GetMaxDate]()
  AND ISNULL(s.[DeletionMark], 0) = 0;
GO
