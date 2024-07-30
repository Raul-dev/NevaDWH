
-- SET LANGUAGE English --  Russian
CREATE PROCEDURE [dbo].[sp_FillDimDate]
    @FromDate   datetime, 
    @ToDate     datetime,
    @Culture    nvarchar(128) = 'ru-ru',
    @TableName  nvarchar(128) = NULL,
    @IsOutput   bit = 0
AS
SET CONCAT_NULL_YIELDS_NULL ON
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'                        
    SET @ProcedureParams =
    '@FromDate='+ISNULL('''' + CAST(@FromDate AS varchar(19) ) + '''','NULL') + ' ' +
    '@ToDate='+ISNULL('''' + CAST(@ToDate AS varchar(19) ) + '''','NULL') + ' ' +
    '@Culture='+ISNULL('''' + @Culture + '''','NULL') + ' ' +
    '@TableName='+ISNULL('''' + @TableName + '''','NULL') 
    EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

-- SET @Culture='ru-ru'; -- 'en-US'
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
    [LastOfMonth]          = EOMONTH(DateCalendarValue) ,
    [FirstOfQuarter]       = CONVERT(nvarchar(10),DATEADD(qq, DATEDIFF(qq, 0, DateCalendarValue), 0), 23),
    [LastOfQuarter]        = CONVERT(nvarchar(10), DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, DateCalendarValue) +1, 0)), 23)
    INTO #NewDate
FROM [Days]
ORDER BY DateCalendarValue
OPTION (MAXRECURSION 0);
SET @RowCount = @@ROWCOUNT

IF( @TableName is NULL) 
    INSERT INTO [dbo].[DIM_Date]([DateID], [FullDateAlternateKey], [DayNumberOfYear], [DayNumberOfMonth], [DayNumberOfQuarter], [MonthNumberOfYear], [MonthNumberOfQuarter], [CalendarQuarter], [CalendarYear], [DayName], [MonthName], [LastOfMonth], [FirstOfQuarter], [LastOfQuarter])
    SELECT new.[DateID], new.[FullDateAlternateKey], new.[DayNumberOfYear], new.[DayNumberOfMonth], new.[DayNumberOfQuarter], new.[MonthNumberOfYear], new.[MonthNumberOfQuarter], new.[CalendarQuarter], new.[CalendarYear], new.[DayName], new.[MonthName], new.[LastOfMonth], new.[FirstOfQuarter], new.[LastOfQuarter] 
    FROM #NewDate new 
    LEFT JOIN [dbo].[DIM_Date] d ON new.[DateID] = d.[DateID]
    WHERE d.[DateID] is NULL

IF( NOT @TableName is NULL) 
    EXEC( 'SELECT [DateID], new.[FullDateAlternateKey], new.[DayNumberOfYear], new.[DayNumberOfMonth], new.[DayNumberOfQuarter], new.[MonthNumberOfYear], new.[MonthNumberOfQuarter], new.[CalendarQuarter], new.[CalendarYear], new.[DayName], new.[MonthName], new.[LastOfMonth], new.[FirstOfQuarter], new.[LastOfQuarter]
            INTO ' + @TableName + '
            FROM #NewDate new
            ')

IF @IsOutput = 1
    SELECT * FROM #NewDate

EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount

GO
