
-- SET LANGUAGE English --  Russian

CREATE PROCEDURE [dbo].[sp_FillDimDate]
    @FromDate datetime, 
    @ToDate datetime,
    @Culture nvarchar(128),
    @TableName nvarchar(128) = NULL,
    @IsOutput bit = 1
AS
SET CONCAT_NULL_YIELDS_NULL ON

DECLARE @RowCount int;
-- Debug
-- SET @Culture='ru-ru'; -- 'en-US'
-- SELECT @FromDate = '20060101', @ToDate = '20061231';
SET NOCOUNT ON;
WITH Days(DateCalendarValue, ID) AS
(
    SELECT @FromDate, 1 WHERE @FromDate <= @ToDate
    UNION ALL
    SELECT DATEADD(DAY,1,DateCalendarValue), ID+1  FROM Days WHERE DateCalendarValue < @ToDate
)

SELECT 
    [DateID] = CAST(CONVERT(varchar(25), DateCalendarValue, 112) as int) ,
    [FullDateAlternateKey] = CAST(DateCalendarValue as date),
    [DayNumberOfYear]      = DATEPART(dayofyear, DateCalendarValue),
    [DayNumberOfMonth]     = DATEPART(day, DateCalendarValue),
    [DayNumberOfQuarter]   = DATEDIFF(dd,DATEADD(qq, DATEDIFF(qq, 0, DateCalendarValue), 0), DateCalendarValue) + 1,
    [MonthNumberOfYear]    = DATEPART(month, DateCalendarValue),
    [MonthNumberOfQuarter] = MONTH(DateCalendarValue) - MONTH(DATEADD(qq, DATEDIFF(qq, 0, DateCalendarValue), 0)) + 1,
    [CalendarQuarter]      = DATEPART(quarter, DateCalendarValue),
    [CalendarYear]         = DATEPART(year, DateCalendarValue),
    [DayName]              = FORMAT(DateCalendarValue, 'dddd', @Culture),
    [MonthName]            = FORMAT(DateCalendarValue, 'MMMM', @Culture),
    [LastOfMonth]            = EOMONTH(DateCalendarValue) ,
    [FirstOfQuarter]         = CONVERT(nvarchar(10),DATEADD(qq, DATEDIFF(qq, 0, DateCalendarValue), 0), 23),
    [LastOfQuarter]          = CONVERT(nvarchar(10), DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, DateCalendarValue) +1, 0)), 23)
    INTO #NewDate
FROM [Days]
ORDER BY DateCalendarValue
OPTION (MAXRECURSION 0);
SET @RowCount = @@ROWCOUNT


IF( @TableName is NULL) 
    INSERT INTO [dbo].[Dim_date]([DateID], [FullDateAlternateKey], [DayNumberOfYear], [DayNumberOfMonth], [DayNumberOfQuarter], [MonthNumberOfYear], [MonthNumberOfQuarter], [CalendarQuarter], [CalendarYear], [DayName], [MonthName], [LastOfMonth], [FirstOfQuarter], [LastOfQuarter])
    SELECT new.[DateID], new.[FullDateAlternateKey], new.[DayNumberOfYear], new.[DayNumberOfMonth], new.[DayNumberOfQuarter], new.[MonthNumberOfYear], new.[MonthNumberOfQuarter], new.[CalendarQuarter], new.[CalendarYear], new.[DayName], new.[MonthName], new.[LastOfMonth], new.[FirstOfQuarter], new.[LastOfQuarter] 
    FROM #NewDate new LEFT JOIN [dbo].[Dim_date] d ON new.[DateID] = d.[DateID]
    WHERE d.[DateID] is NULL

IF( NOT @TableName is NULL) 
    EXEC( 'SELECT [DateID], new.[FullDateAlternateKey], new.[DayNumberOfYear], new.[DayNumberOfMonth], new.[DayNumberOfQuarter], new.[MonthNumberOfYear], new.[MonthNumberOfQuarter], new.[CalendarQuarter], new.[CalendarYear], new.[DayName], new.[MonthName], new.[LastOfMonth], new.[FirstOfQuarter], new.[LastOfQuarter]
            into ' + @TableName + '
            FROM #NewDate new
            ')


IF @IsOutput = 1
    SELECT * FROM #NewDate


GO