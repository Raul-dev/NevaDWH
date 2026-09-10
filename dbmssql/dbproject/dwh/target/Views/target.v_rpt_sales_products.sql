CREATE VIEW [target].[v_rpt_sales_products]
AS
SELECT
  s.[id] AS [SaleId],
  s.[RefID] AS [SaleRefID],
  s.[Number] AS [SaleNumber],
  s.[Date] AS [SaleDateTime],
  s.[DateID],
  d.[FullDateAlternateKey] AS [SaleDate],
  d.[CalendarYear],
  d.[CalendarQuarter],
  d.[MonthNumberOfYear],
  s.[Клиент] AS [ClientRef],
  c.[Code] AS [ClientCode],
  c.[Description] AS [ClientName],
  s.[ТипДоставки],
  l.[id] AS [LineId],
  l.[Товар] AS [ProductRef],
  p.[Code] AS [ProductCode],
  p.[Description] AS [ProductName],
  p.[Описание] AS [ProductDescription],
  l.[Доставка],
  l.[Колличество] AS [Qty],
  l.[Цена] AS [Price],
  ISNULL(l.[Колличество], 0) * ISNULL(l.[Цена], 0) AS [Amount]
FROM [target].[FACT_Продажи] AS s
INNER JOIN [target].[FACT_Продажи.Товары] AS l
  ON l.[FACT_ПродажиRefID] = s.[RefID]
  AND l.[end_date] = [mq].[fn_GetMaxDate]()
LEFT JOIN [target].[DIM_Date] AS d
  ON d.[DateID] = s.[DateID]
LEFT JOIN [target].[DIM_Клиенты] AS c
  ON c.[end_date] = [mq].[fn_GetMaxDate]()
  AND c.[DeletionMark] = 0
  AND CAST(c.[RefID] AS varchar(36)) = s.[Клиент]
LEFT JOIN [target].[DIM_Товары] AS p
  ON p.[end_date] = [mq].[fn_GetMaxDate]()
  AND p.[DeletionMark] = 0
  AND CAST(p.[RefID] AS varchar(36)) = l.[Товар]
WHERE s.[end_date] = [mq].[fn_GetMaxDate]()
  AND ISNULL(s.[DeletionMark], 0) = 0;
GO
