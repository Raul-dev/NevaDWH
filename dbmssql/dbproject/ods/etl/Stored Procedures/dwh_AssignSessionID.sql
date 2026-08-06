CREATE PROCEDURE [etl].[dwh_AssignSessionID]
  @DwhSessionId bigint = NULL OUTPUT, -- @DwhSessionId = -1 create new package
  @RowCount       int = NULL OUTPUT,
  @ErrorMessage   varchar(MAX) = NULL OUTPUT
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256)
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[etl].[dwh_AssignSessionID]'
  SET @ProcedureParams =
    '@DwhSessionId=' + ISNULL(LTRIM(STR(@DwhSessionId)),'NULL')

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET DEADLOCK_PRIORITY HIGH
BEGIN TRY

  SET @RowCount = 0
  DECLARE @T AS TABLE (DwhSessionId bigint)

  IF NOT @DwhSessionId IS NULL AND @DwhSessionId != -1
  BEGIN

    SELECT s.[DwhSessionId], sum(p.[RowCount]) as row_count, @ErrorMessage AS ErrMessage,     MAX(s.[CreateSession]) AS create_session
    FROM [etl].[DwhSession] s
      INNER JOIN [etl].[DwhProcessingDetails] p ON p.[DwhSessionId] = s.[DwhSessionId]
    WHERE [DwhSessionStateId] = 2 AND s.[DwhSessionId] = @DwhSessionId
    GROUP BY s.[DwhSessionId]
    EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = 1, @ProcedureInfo = 'RETURN Line 39'
    RETURN 0;
  END
  IF @DwhSessionId IS NULL OR @DwhSessionId = -1
  BEGIN
    SELECT @DwhSessionId = min([DwhSessionId]) FROM [etl].[DwhSession] WHERE ISNULL(@DwhSessionId, 0) != -1 AND [DwhSessionStateId] = 2
    IF NOT @DwhSessionId IS NULL
    BEGIN
      SELECT [DwhSessionId], sum([RowCount]) as row_count, @ErrorMessage AS ErrMessage, (SELECT [CreateSession] FROM [etl].[DwhSession] WHERE [DwhSessionId] = @DwhSessionId) as create_session FROM [etl].[DwhProcessingDetails] WHERE [DwhSessionId] = @DwhSessionId
      GROUP BY [DwhSessionId]
      EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = 1, @ProcedureInfo = 'RETURN Line 49'
      RETURN 0;
    END
    INSERT @T EXEC [etl].[dwh_SaveSessionState]
    SELECT @DwhSessionId = DwhSessionId FROM @T t
    SET @ProcedureInfo = 'Create @DwhSessionId='+LTRIM(STR(@DwhSessionId))
    EXEC [audit].[sp_LogInfo] @LogID = @LogID, @ProcedureInfo = @ProcedureInfo
  END

  DECLARE @LocalRowCount int
BEGIN TRANSACTION
  CREATE TABLE #DIM_Валюты(
    [OdsId] bigint Primary Key,
    [RefID] uniqueidentifier
  )
  INSERT INTO #DIM_Валюты (
    [OdsId],
    [RefID]
  )
  SELECT [OdsId], [RefID] FROM [odins].[DIM_Валюты] WITH(XLOCK)
  SET @LocalRowCount = @@ROWCOUNT
  SELECT @RowCount = @RowCount + @LocalRowCount
  IF @LocalRowCount > 0
    INSERT [etl].[DwhProcessingDetails]([DwhSessionId], [SchemaName], [TableName], [RowCount])
    SELECT @DwhSessionId, 'odins', 'DIM_Валюты',@LocalRowCount

  INSERT INTO [odins].[DIM_Валюты_history](
    [NKey],
    [DwhSessionId],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [ЗагружаетсяИзИнтернета],
    [НаименованиеПолное],
    [Наценка],
    [ОсновнаяВалюта],
    [ПараметрыПрописи],
    [ФормулаРасчетаКурса],
    [СпособУстановкиКурса],
    [CreatedAt]
  )
  SELECT
    b.[NKey],
    @DwhSessionId AS [DwhSessionId],
    b.[RefID],
    b.[DeletionMark],
    b.[Code],
    b.[Description],
    b.[ЗагружаетсяИзИнтернета],
    b.[НаименованиеПолное],
    b.[Наценка],
    b.[ОсновнаяВалюта],
    b.[ПараметрыПрописи],
    b.[ФормулаРасчетаКурса],
    b.[СпособУстановкиКурса],
    GetDate() AS [CreatedAt]
  FROM [odins].[DIM_Валюты] b
    INNER JOIN #DIM_Валюты ll ON b.[OdsId] = ll.[OdsId]

  INSERT INTO [odins].[DIM_Валюты.Представления_history](
    [NKey],
    [DwhSessionId],
    [DIM_ВалютыRefID],
    [КодЯзыка],
    [ПараметрыПрописи],
    [CreatedAt]
  )
  SELECT
    b.[NKey],
    @DwhSessionId AS [DwhSessionId],
    b.[DIM_ВалютыRefID],
    b.[КодЯзыка],
    b.[ПараметрыПрописи],
    GetDate() AS [CreatedAt]
  FROM [odins].[DIM_Валюты.Представления] b
    INNER JOIN #DIM_Валюты ll ON b.[DIM_ВалютыRefID] = ll.[RefID]
  SET @LocalRowCount = @@ROWCOUNT
  SELECT @RowCount = @RowCount + @LocalRowCount
  IF @LocalRowCount > 0
    INSERT [etl].[DwhProcessingDetails]([DwhSessionId], [SchemaName], [TableName], [RowCount])
    SELECT @DwhSessionId, 'odins', 'DIM_Валюты.Представления', @LocalRowCount


COMMIT TRANSACTION
BEGIN TRANSACTION
  CREATE TABLE #DIM_Клиенты(
    [OdsId] bigint Primary Key,
    [RefID] uniqueidentifier
  )
  INSERT INTO #DIM_Клиенты (
    [OdsId],
    [RefID]
  )
  SELECT [OdsId], [RefID] FROM [odins].[DIM_Клиенты] WITH(XLOCK)
  SET @LocalRowCount = @@ROWCOUNT
  SELECT @RowCount = @RowCount + @LocalRowCount
  IF @LocalRowCount > 0
    INSERT [etl].[DwhProcessingDetails]([DwhSessionId], [SchemaName], [TableName], [RowCount])
    SELECT @DwhSessionId, 'odins', 'DIM_Клиенты',@LocalRowCount

  INSERT INTO [odins].[DIM_Клиенты_history](
    [NKey],
    [DwhSessionId],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [Контакт],
    [CreatedAt]
  )
  SELECT
    b.[NKey],
    @DwhSessionId AS [DwhSessionId],
    b.[RefID],
    b.[DeletionMark],
    b.[Code],
    b.[Description],
    b.[Контакт],
    GetDate() AS [CreatedAt]
  FROM [odins].[DIM_Клиенты] b
    INNER JOIN #DIM_Клиенты ll ON b.[OdsId] = ll.[OdsId]


COMMIT TRANSACTION
BEGIN TRANSACTION
  CREATE TABLE #DIM_Товары(
    [OdsId] bigint Primary Key,
    [RefID] uniqueidentifier
  )
  INSERT INTO #DIM_Товары (
    [OdsId],
    [RefID]
  )
  SELECT [OdsId], [RefID] FROM [odins].[DIM_Товары] WITH(XLOCK)
  SET @LocalRowCount = @@ROWCOUNT
  SELECT @RowCount = @RowCount + @LocalRowCount
  IF @LocalRowCount > 0
    INSERT [etl].[DwhProcessingDetails]([DwhSessionId], [SchemaName], [TableName], [RowCount])
    SELECT @DwhSessionId, 'odins', 'DIM_Товары',@LocalRowCount

  INSERT INTO [odins].[DIM_Товары_history](
    [NKey],
    [DwhSessionId],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [Описание],
    [CreatedAt]
  )
  SELECT
    b.[NKey],
    @DwhSessionId AS [DwhSessionId],
    b.[RefID],
    b.[DeletionMark],
    b.[Code],
    b.[Description],
    b.[Описание],
    GetDate() AS [CreatedAt]
  FROM [odins].[DIM_Товары] b
    INNER JOIN #DIM_Товары ll ON b.[OdsId] = ll.[OdsId]


COMMIT TRANSACTION
BEGIN TRANSACTION
  CREATE TABLE #FACT_Продажи(
    [OdsId] bigint Primary Key,
    [RefID] uniqueidentifier
  )
  INSERT INTO #FACT_Продажи (
    [OdsId],
    [RefID]
  )
  SELECT [OdsId], [RefID] FROM [odins].[FACT_Продажи] WITH(XLOCK)
  SET @LocalRowCount = @@ROWCOUNT
  SELECT @RowCount = @RowCount + @LocalRowCount
  IF @LocalRowCount > 0
    INSERT [etl].[DwhProcessingDetails]([DwhSessionId], [SchemaName], [TableName], [RowCount])
    SELECT @DwhSessionId, 'odins', 'FACT_Продажи',@LocalRowCount

  INSERT INTO [odins].[FACT_Продажи_history](
    [NKey],
    [DwhSessionId],
    [RefID],
    [DeletionMark],
    [Number],
    [Posted],
    [Date],
    [DateID],
    [ДатаОтгрузки],
    [ДатаОтгрузкиID],
    [Клиент],
    [ТипДоставки],
    [ПримерСоставногоТипа],
    [ПримерСоставногоТипа_ТипЗначения],
    [CreatedAt]
  )
  SELECT
    b.[NKey],
    @DwhSessionId AS [DwhSessionId],
    b.[RefID],
    b.[DeletionMark],
    b.[Number],
    b.[Posted],
    b.[Date],
    b.[DateID],
    b.[ДатаОтгрузки],
    b.[ДатаОтгрузкиID],
    b.[Клиент],
    b.[ТипДоставки],
    b.[ПримерСоставногоТипа],
    b.[ПримерСоставногоТипа_ТипЗначения],
    GetDate() AS [CreatedAt]
  FROM [odins].[FACT_Продажи] b
    INNER JOIN #FACT_Продажи ll ON b.[OdsId] = ll.[OdsId]

  INSERT INTO [odins].[FACT_Продажи.Товары_history](
    [NKey],
    [DwhSessionId],
    [FACT_ПродажиRefID],
    [Доставка],
    [Товар],
    [Колличество],
    [Цена],
    [CreatedAt]
  )
  SELECT
    b.[NKey],
    @DwhSessionId AS [DwhSessionId],
    b.[FACT_ПродажиRefID],
    b.[Доставка],
    b.[Товар],
    b.[Колличество],
    b.[Цена],
    GetDate() AS [CreatedAt]
  FROM [odins].[FACT_Продажи.Товары] b
    INNER JOIN #FACT_Продажи ll ON b.[FACT_ПродажиRefID] = ll.[RefID]
  SET @LocalRowCount = @@ROWCOUNT
  SELECT @RowCount = @RowCount + @LocalRowCount
  IF @LocalRowCount > 0
    INSERT [etl].[DwhProcessingDetails]([DwhSessionId], [SchemaName], [TableName], [RowCount])
    SELECT @DwhSessionId, 'odins', 'FACT_Продажи.Товары', @LocalRowCount


COMMIT TRANSACTION

  -- Deleted and create session
  IF @RowCount > 0
  BEGIN
  BEGIN TRANSACTION
    -- Delete star: odins.DIM_Валюты
    DELETE b FROM [odins].[DIM_Валюты] b
      INNER JOIN #DIM_Валюты ll ON b.[OdsId] = ll.[OdsId]
      -- Delete child: odins.DIM_Валюты.Представления
      DELETE b FROM [odins].[DIM_Валюты.Представления] b
        INNER JOIN #DIM_Валюты ll ON b.[DIM_ВалютыRefID] = ll.[RefID]
    -- Delete star: odins.DIM_Клиенты
    DELETE b FROM [odins].[DIM_Клиенты] b
      INNER JOIN #DIM_Клиенты ll ON b.[OdsId] = ll.[OdsId]
    -- Delete star: odins.DIM_Товары
    DELETE b FROM [odins].[DIM_Товары] b
      INNER JOIN #DIM_Товары ll ON b.[OdsId] = ll.[OdsId]
    -- Delete star: odins.FACT_Продажи
    DELETE b FROM [odins].[FACT_Продажи] b
      INNER JOIN #FACT_Продажи ll ON b.[OdsId] = ll.[OdsId]
      -- Delete child: odins.FACT_Продажи.Товары
      DELETE b FROM [odins].[FACT_Продажи.Товары] b
        INNER JOIN #FACT_Продажи ll ON b.[FACT_ПродажиRefID] = ll.[RefID]
    EXEC [etl].[dwh_SaveSessionState] @DwhSessionId = @DwhSessionId, @DwhSessionStateId = 2
  COMMIT TRANSACTION
  END

  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @LocalRowCount

  SELECT @DwhSessionId AS [DwhSessionId], @RowCount AS row_count, @ErrorMessage AS ErrMessage, (SELECT [CreateSession] FROM [etl].[DwhSession] WHERE [DwhSessionId] = @DwhSessionId) as create_session

RETURN 0
END TRY
BEGIN CATCH
  SELECT @ErrorMessage = ERROR_MESSAGE()
  IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
  BEGIN
    ROLLBACK TRANSACTION
  END

  UPDATE [etl].[DwhSession] SET [DwhSessionStateId] = 3
  WHERE [DwhSessionId] = @DwhSessionId
  INSERT [etl].[DwhSessionLog] ([DwhSessionId], [DwhSessionStateId], [ErrorMessage])
  SELECT [DwhSessionId]    = @DwhSessionId,
    [DwhSessionStateId] = 3,
    [ErrorMessage]      = 'AssignSessionID Error: ' + @ErrorMessage
  SET @RowCount = @@ROWCOUNT
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

  SELECT @DwhSessionId, -1 as row_count, @ErrorMessage AS ErrMessage
  RETURN -1
END CATCH

END

GO
