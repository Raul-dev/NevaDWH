/*
SELECT * FROM [audit].[LogProcedures]
SELECT * FROM [odins].[DIM_ТоварыBuffer]
SELECT * FROM [odins].[DIM_Товары]

DECLARE @RowCount     int,
  @BufferId           bigint,
  @ErrorMessage       varchar(4000),
  @Debug              bit = 1
UPDATE D SET 
  [UpdatedAt] = [mq].[fn_GetMinDate]()
FROM [odins].[DIM_ТоварыBuffer] D
EXEC [odins].[load_DIM_Товары]
  @RowCount           = @RowCount OUTPUT,
  @BufferId           = @BufferId  OUTPUT,
  @ErrorMessage       = @ErrorMessage OUTPUT,
  @Debug              = @Debug

*/
CREATE PROCEDURE [odins].[load_DIM_Товары]
  @SessionId          bigint         = NULL,
  @BufferHistoryMode  tinyint        = 0,   -- 0 - Do not delete the buffering history.
                                            -- 1 - Delete the buffering history.
                                            -- 2 - Keep the buffering history for 10 days.
                                            -- 3 - Keep the buffering history for a month.
  @RowCount           int           = NULL OUTPUT,
  @BufferId           bigint        = NULL OUTPUT,
  @ErrorMessage       varchar(4000) = NULL OUTPUT,
  @Debug              bit           = 0
AS
BEGIN
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256)
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcEtl')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[odins].[load_DIM_Товары]'
  SET @ProcedureParams =
    '@SessionId=' + ISNULL(LTRIM(STR(@SessionId)),'NULL') + ', ' +
    '@BufferHistoryMode=' + ISNULL(LTRIM(STR(@BufferHistoryMode, 30)),'NULL') + ', ' +
    '@BufferId=' + ISNULL(LTRIM(STR(@BufferId, 30)),'NULL')
END
SET XACT_ABORT OFF

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET DEADLOCK_PRIORITY LOW
DECLARE @MinDate      datetime2(4)  = [mq].[fn_GetMinDate](),
  @UpdateDate         datetime2(4)  = GetDate(),
  @BufferHistoryDays  int,
  @BatchSize          int           = 200000

SET @BufferHistoryDays = IIF(@BufferHistoryMode = 2, 10, 30)

DECLARE @LockedList AS TABLE(
  [BufferId] bigint Primary key,
  [MessageId] uniqueidentifier,
  [RefID] uniqueidentifier,
  [MessageTypeId] tinyint
)
DECLARE @LockedListUniq AS TABLE(
  [BufferId] bigint Primary key,
  [RefID] uniqueidentifier
)

BEGIN TRY
BEGIN TRANSACTION

  IF @AuditEnable IS NOT NULL 
    EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT

  IF ISNULL(@BufferId, 0) <= 0
    INSERT INTO @LockedList ([BufferId], [MessageId], [RefID], [MessageTypeId])
    SELECT TOP (@BatchSize) [BufferId], [MessageId], [RefID], [MessageTypeId]
    FROM [odins].[DIM_ТоварыBuffer] b 
    WHERE b.[UpdatedAt] = @MinDate
    ORDER BY [BufferId]
  ELSE
    INSERT INTO @LockedList ([BufferId], [MessageId], [RefID], [MessageTypeId])
    SELECT TOP (@BatchSize) [BufferId], [MessageId], [RefID], [MessageTypeId]
    FROM [odins].[DIM_ТоварыBuffer] b 
    WHERE [BufferId] >= @BufferId
      AND b.[UpdatedAt] = @MinDate
    ORDER BY [BufferId]

  SET @RowCount = @@ROWCOUNT;

  IF @Debug = 1
    SELECT [@LockedList] = '@LockedList', * FROM @LockedList
  IF @RowCount = 0 
  BEGIN
  
    EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = 0, @ProcedureInfo = 'Empty buffer'
    COMMIT TRANSACTION
    RETURN 0
  END

  IF EXISTS (SELECT 1 FROM @LockedList WHERE [MessageTypeId] = 2)
  BEGIN

    ;WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
    INSERT INTO [mq].[FileQueue] ([SessionId], [MessageKey], [MessageId], [StartDate], [FinishDate], [FileName], [FileFolder], [FileType], [ErrorMessage], [StateId], [CreatedAt])
    SELECT
      @SessionId AS [SessionId],
      b.[MessageBody].value('(/Data/ПолноеИмя/text())[1]', 'varchar(4000)') [MessageKey],
      b.[MessageId] [MessageId],
      b.[MessageBody].value('(/Data/Реквизиты/НачалоФормирования/text())[1]', 'datetime2(4)')  AS [StartDate],
      b.[MessageBody].value('(/Data/Реквизиты/КонецФормирования/text())[1]', 'datetime2(4)')  AS [FinishDate],
      b.[MessageBody].value('(/Data/Реквизиты/ИмяФайла/text())[1]', 'varchar(4000)') AS [FileName],
      b.[MessageBody].value('(/Data/Реквизиты/ИмяПапки/text())[1]', 'varchar(4000)') AS [FileFolder],
      'xml' AS [FileType],
      NULL [ErrorMessage],
      1 [StateId],
      b.[CreatedAt]
    FROM [odins].[DIM_ТоварыBuffer] b
    INNER JOIN @LockedList l ON b.[BufferId] = l.[BufferId]
    WHERE l.[MessageTypeId] = 2 AND NOT EXISTS(SELECT 1 FROM [mq].[FileQueue] f WHERE f.[MessageKey] = 'CatalogObject.Товары' AND f.[MessageId] = l.[MessageId] AND f.[CreatedAt] = b.[CreatedAt]);

    DECLARE @FileQueueID bigint, @res int
    SELECT @FileQueueID = MIN([FileQueueId]) FROM [mq].[FileQueue] f WHERE f.[MessageKey] = 'CatalogObject.Товары' AND [StateId] in (1,3)
    COMMIT TRANSACTION
    EXEC @res = [odins].[load_DIM_Товары_file] @FileQueueID = @FileQueueID, @ErrorMessage = @ErrorMessage OUTPUT
    IF @res <> 0 BEGIN
      EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = 0, @ProcedureInfo = 'load_file @res<>0'
      RETURN
    END
    BEGIN TRANSACTION
  END

  INSERT INTO @LockedListUniq
  SELECT [BufferId] = MAX([BufferId]), [RefID]
  FROM @LockedList l
  WHERE l.[MessageTypeId] = 1 
  GROUP BY [RefID]
  SET @RowCount = @@ROWCOUNT;

  SELECT DISTINCT tmp = 1 INTO #tmpDIM_Товары
  FROM [odins].[DIM_Товары] b WITH(ROWLOCK,XLOCK)
  INNER JOIN @LockedListUniq ll ON b.[RefID] = ll.[RefID];

  TRUNCATE TABLE [staging].[DIM_Товары];
  SET @UpdateDate = GetDate();
  ;WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config', 'http://www.w3.org/2001/XMLSchema-instance' as xsi)
  INSERT [staging].[DIM_Товары]([NKey],   [RefID],  [DeletionMark],  [Code],  [Description],  [Описание], [UpdatedAt])
  SELECT
    [NKey] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
    [RefID] = X.C.value('(Ref/text())[1]', 'uniqueidentifier'),
    [DeletionMark] = X.C.value('(DeletionMark/text())[1]', 'bit'),
    [Code] = X.C.value('(Code/text())[1]', 'varchar(128)'),
    [Description] = X.C.value('(Description/text())[1]', 'varchar(128)'),
    [Описание] = X.C.value('(Описание/text())[1]', 'varchar(255)'),
    [UpdatedAt] = @UpdateDate
  FROM [odins].[DIM_ТоварыBuffer] AS b
  INNER JOIN @LockedListUniq l ON l.[BufferId] = b.[BufferId]
  CROSS APPLY b.[MessageBody].nodes('/Data/Реквизиты/CatalogObject.Товары') AS X(C);

  IF @Debug = 1
    SELECT [staging_DIM_Товары] = 'staging_DIM_Товары', * FROM [staging].[DIM_Товары]

  EXEC [odins].[load_DIM_Товары_staging]

  -- Clear buffer table
  IF @BufferHistoryMode = 1 AND NOT EXISTS (SELECT 1 FROM [odins].[DIM_ТоварыBuffer] WHERE [IsError] = 1)
  BEGIN
    DELETE b
    FROM [odins].[DIM_ТоварыBuffer] b
    INNER JOIN @LockedList t ON b.[BufferId] = t.[BufferId]
  END
  ELSE
  BEGIN
    UPDATE b SET
      [UpdatedAt] = @UpdateDate
    FROM [odins].[DIM_ТоварыBuffer] AS b
    INNER JOIN @LockedList l ON l.[BufferId] = b.[BufferId]

    IF @BufferHistoryMode >= 2 AND NOT EXISTS (SELECT 1 FROM [odins].[DIM_ТоварыBuffer] WHERE [IsError] = 1)
      DELETE b
      FROM [odins].[DIM_ТоварыBuffer] b
      WHERE DATEDIFF(DD, @UpdateDate, [UpdatedAt]) > @BufferHistoryDays
  END
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount

COMMIT TRANSACTION
END TRY
BEGIN CATCH
  SET @ErrorMessage = ERROR_MESSAGE()
  IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    ROLLBACK TRANSACTION

  DECLARE @err_SessionId bigint;
  SET @err_SessionId = ISNULL(@SessionId, 0)
  INSERT [mq].[SessionLog] ([SessionId], [SessionStateId], [ErrorMessage])
  SELECT
    [SessionId] = @err_SessionId,
    [SessionStateId] = 3,
    [ErrorMessage] = 'Table [odins].[DIM_ТоварыBuffer]. Error: ' + @ErrorMessage

  IF NOT @ErrorMessage LIKE '%deadlock%'
    UPDATE b SET 
      [SessionId] = @err_SessionId,
      [IsError]   = 1,
      [UpdatedAt]  = ISNULL(@UpdateDate, GetDate())
    FROM [odins].[DIM_ТоварыBuffer] b
    INNER JOIN @LockedList l ON b.[BufferId] = l.[BufferId]
    WHERE [IsError] = 0

  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage
  EXEC [audit].[sp_Print] @StrPrint = @ErrorMessage, @PrintLevel = 4
  RETURN -1
END CATCH

END

GO
