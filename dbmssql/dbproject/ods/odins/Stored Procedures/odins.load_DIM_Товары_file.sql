CREATE PROCEDURE [odins].[load_DIM_Товары_file]
  @FileQueueID  bigint = NULL,
  @FileOverride nvarchar(4000) = NULL,
  @ErrorMessage varchar(4000) = NULL OUTPUT
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256), @RowCount int
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[odins].[load_DIM_Товары_file]'
  SET @ProcedureParams =
    '@FileQueueID=' + ISNULL(LTRIM(STR(@FileQueueID)),'NULL') + ', ' +
    '@FileOverride=' + ISNULL('''' +CAST(@FileOverride AS varchar(19) ) + '''','NULL')

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

--SET TRANSACTION ISOLATION LEVEL READ COMMITTED
--SET DEADLOCK_PRIORITY LOW
DECLARE @FilePath nvarchar(4000)
DECLARE @FormatFilePath nvarchar(4000)
DECLARE @SqlCmd nvarchar(Max), @IsSingleFile bit = 0
DECLARE @MsgKey nvarchar(256) = 'CatalogObject.Товары';
DECLARE @IdError bigint = 0

BEGIN TRY

    IF NOT @FileQueueID IS NULL OR LEN(ISNULL(@FileOverride,'')) > 0
    BEGIN
      SET @IsSingleFile = 1
      IF LEN(ISNULL(@FileOverride,'')) > 0
        SET @FileQueueID = 0
      ELSE
      BEGIN
        SELECT @ErrorMessage = [ErrorMessage], @IdError = [FileQueueId] FROM [mq].[FileQueue] WHERE [StateId] = 3
        IF @IdError <> 0
          RAISERROR( N'Загрузка FileQueueID=[%d], Вызвала ошибку [%s]. Дальнейшие загрузки остановлены.', 16, 1, @IdError, @ErrorMessage)
      END
    END
    ELSE
    BEGIN
      SET @FileQueueID = 0
      IF NOT EXISTS(SELECT TOP 1 [FileQueueId] FROM [mq].[FileQueue]
        WHERE [MessageKey] = @MsgKey AND NOT [FileName] IS NULL AND [StateId] = 1 AND ([StateId] >= @FileQueueID ))
      BEGIN 
        EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = 0, @ProcedureInfo = 'Not exists filequeue_id'
        RETURN 0
      END
    END

    WHILE (NOT @FileQueueID IS NULL )
    BEGIN
      SELECT @FileQueueID = (SELECT TOP 1 [FileQueueId] FROM [mq].[FileQueue]
      WHERE [MessageKey] = @MsgKey AND NOT [FileName] IS NULL AND [StateId] = 1 AND  ([FileQueueId] >= @FileQueueID AND @IsSingleFile = 0 OR @IsSingleFile = 1 AND [FileQueueId] = @FileQueueID) ORDER BY [FileQueueId] ASC )

      SELECT @FilePath = [FileFolder] + '\' + [FileName],
        @FormatFilePath= [FileFolder] + '\' + 'format.xml'
      FROM [mq].[FileQueue] WHERE [FileQueueId] = @FileQueueID

      IF @IsSingleFile = 1 AND NOT @FileOverride IS NULL
      BEGIN
        SET @FilePath = @FileOverride
        SET @FormatFilePath= LEFT(@FileOverride, LEN(@FileOverride) - CHARINDEX('\', REVERSE(@FileOverride))+1) + 'format.xml' 
      END

      IF NOT @FilePath IS NULL
      BEGIN

        TRUNCATE TABLE staging.DIM_Товары

        SELECT @SqlCmd = N';WITH XMLNAMESPACES (DEFAULT ''http://v8.1c.ru/8.1/data/enterprise/current-config'', ''http://www.w3.org/2001/XMLSchema-instance'' as xsi)
        INSERT staging.DIM_Товары([NKey], [RefID], [DeletionMark], [Code], [Description], [Описание], [UpdatedAt])
        SELECT
          [NKey] = X.C.value(''(Ref/text())[1]'', ''uniqueidentifier'') ,
          [RefID] = X.C.value(''(Ref/text())[1]'', ''uniqueidentifier''),
          [DeletionMark] = X.C.value(''(DeletionMark/text())[1]'', ''bit''),
          [Code] = X.C.value(''(Code/text())[1]'', ''varchar(128)''),
          [Description] = X.C.value(''(Description/text())[1]'', ''varchar(128)''),
          [Описание] = X.C.value(''(Описание/text())[1]'', ''varchar(255)''),
          [UpdatedAt] = GetDate()
        FROM OPENROWSET(BULK ''' + @FilePath + ''', SINGLE_BLOB, CODEPAGE = ''65001'') AS T(File_xml)
          CROSS APPLY (VALUES (CAST(T.File_xml AS xml)) ) AS T2(XMLFromFile)
          CROSS APPLY T2.XMLFromFile.nodes(''/Data/Реквизиты/CatalogObject.Товары'') AS X(C);
        '
        EXEC [audit].[sp_Print] @SqlCmd, 2
        EXEC dbo.sp_executesql @SqlCmd

        DELETE src
          FROM staging.DIM_Товары src
          INNER JOIN (
            SELECT [NKey], [Id] = MAX([Id]) FROM staging.DIM_Товары
            GROUP BY [NKey]
            HAVING Count(*) > 1
          ) dbl ON dbl.[NKey] = src.[NKey] AND src.[Id] < dbl.[Id]

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED
        BEGIN TRANSACTION
          EXEC [odins].[load_DIM_Товары_staging]
          UPDATE [mq].[FileQueue] SET [StateId] = 2, [UpdatedAt] = GetDate()
          WHERE  [FileQueueId] = @FileQueueID
        COMMIT
      END
      IF @IsSingleFile = 1
        BREAK
    END
  SET @RowCount = @@ROWCOUNT
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount

END TRY
BEGIN CATCH
  SELECT @ErrorMessage = ERROR_MESSAGE()
  IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
  BEGIN
    ROLLBACK TRANSACTION
  END

  IF @IdError = 0
    UPDATE [mq].[FileQueue] SET [StateId] = 3, [ErrorMessage] = @ErrorMessage, [UpdatedAt] = GetDate()
    WHERE [FileQueueId] = @FileQueueID

  SET @RowCount = @@ROWCOUNT
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

  RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
  RETURN -1
END CATCH

END

GO
