CREATE PROCEDURE [mq].[load_MetaData]
  @SessionId          bigint         = NULL,
  @BufferHistoryMode  tinyint        = 0,
  @RowCount           int            = NULL OUTPUT,
  @ErrorMessage       varchar(4000)  = NULL OUTPUT
AS
BEGIN
  SET XACT_ABORT OFF
  SET CONCAT_NULL_YIELDS_NULL ON
  SET NOCOUNT ON

  DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @AuditEnable nvarchar(256)
  SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
  IF @AuditEnable IS NOT NULL
  BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
      SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
    SET @ProcedureName = '[mq].[load_MetaData]'
    SET @ProcedureParams =
      '@SessionId='+ISNULL(LTRIM(STR(@SessionId)),'NULL') + ', ' +
      '@BufferHistoryMode='+ISNULL(LTRIM(STR(@BufferHistoryMode)),'NULL')
    EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
  END

  DECLARE @MinDate datetime2(4) = [mq].[fn_GetMinDate](),
    @UpdateDate datetime2(4),
    @BufferHistoryDays int

  SET @BufferHistoryDays = IIF(@BufferHistoryMode = 2, 10, 30)

  BEGIN TRY
  BEGIN TRANSACTION
    DECLARE @tmp_metadata AS TABLE(
      [Namespace]         nvarchar(256)     COLLATE Cyrillic_General_CI_AS NOT NULL,
      [NamespaceVersion]  nvarchar(256)     COLLATE Cyrillic_General_CI_AS NOT NULL,
      [MessageBody]       nvarchar(max)     COLLATE Cyrillic_General_CI_AS NULL,
      [BufferId]          bigint,
      [SessionId]         bigint,
      [MessageId]         uniqueidentifier,
      [MessageKey]        nvarchar(256)     COLLATE Cyrillic_General_CI_AS NULL,
      [MetaAdapterId]     tinyint           
    );

    ;WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.3/MDClasses','http://v8.1c.ru/8.3/xcf/readable' as xr)
    INSERT @tmp_metadata ([MessageBody], [BufferId], [SessionId], [MessageId], [MessageKey], [MetaAdapterId], [Namespace], [NamespaceVersion])
    SELECT
      [MessageBody], [BufferId], [SessionId], [MessageId], [MessageKey], [MetaAdapterId],
      [Namespace] = CASE [MetaAdapterId] WHEN 4
                THEN JSON_VALUE([MessageBody],'$."Реквизиты"[0]."ПространствоИменИсходное"')
              WHEN 1 THEN 'https://nevadwh.ru' + '/' + COALESCE(CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Document/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
      CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/InformationRegister/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
      CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Catalog/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'))
              ELSE 'unknown'
            END,
      [NamespaceVersion] = CASE [MetaAdapterId] WHEN 4
                THEN JSON_VALUE([MessageBody],'$."Реквизиты"[0]."ПространствоИменСВерсией"')
              WHEN 1 THEN 'https://nevadwh.ru' + '/' + COALESCE(CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Document/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
      CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/InformationRegister/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)'),
      CAST(REPLACE([MessageBody], 'encoding="UTF-8"','') AS xml).value('(/MetaDataObject/Catalog/InternalInfo/xr:GeneratedType/@name)[1]', 'varchar(4000)')) + '/version1'
              ELSE 'unknown'
            END
    FROM [mq].[MetaDataBuffer] WITH (XLOCK)
    WHERE [IsError] = 0;
    SET @RowCount = @@ROWCOUNT

    IF (@RowCount = 0)
    BEGIN
      COMMIT
      RETURN 0
    END

    INSERT INTO [mq].[MetaData] ([NKey], [Namespace], [NamespaceVersion], [MessageBody], [MetaAdapterId])
    SELECT
      CAST(SUBSTRING(HASHBYTES('SHA2_256', COALESCE(p.[MessageBody], '')), 0, 32) AS uniqueidentifier) AS NKey,
      [Namespace], [NamespaceVersion], p.[MessageBody], p.[MetaAdapterId]
    FROM (
      SELECT * FROM @tmp_metadata
      WHERE [BufferId] IN (
        SELECT MAX([BufferId]) FROM @tmp_metadata
        GROUP BY [NamespaceVersion]
      )
    ) p
    WHERE NOT EXISTS (SELECT 1 FROM [mq].[MetaData] l WHERE l.[NamespaceVersion] = p.[NamespaceVersion])

    UPDATE m
      SET m.[MessageBody] = p.[MessageBody]
    FROM [mq].[MetaData] m
    INNER JOIN (
      SELECT [NamespaceVersion], [MessageBody] FROM @tmp_metadata
      WHERE [BufferId] IN (
        SELECT MAX([BufferId]) FROM @tmp_metadata
        GROUP BY [NamespaceVersion]
      )
    ) p ON m.[NamespaceVersion] = p.[NamespaceVersion]

    IF @BufferHistoryMode = 1 AND NOT EXISTS (SELECT 1 FROM [mq].[MetaDataBuffer] WHERE [IsError] = 1)
    BEGIN
      DELETE b
      FROM [mq].[MetaDataBuffer] b
      INNER JOIN @tmp_metadata t ON b.[BufferId] = t.[BufferId]
    END
    ELSE
    BEGIN
      UPDATE b SET [UpdatedAt] = @UpdateDate
      FROM [mq].[MetaDataBuffer] AS b
      INNER JOIN @tmp_metadata l ON l.[BufferId] = b.[BufferId]

      IF @BufferHistoryMode >= 2 AND NOT EXISTS (SELECT 1 FROM [mq].[MetaDataBuffer] WHERE [IsError] = 1)
        DELETE b
        FROM [mq].[MetaDataBuffer] b
        WHERE DATEDIFF(DD, @UpdateDate, [UpdatedAt]) > @BufferHistoryDays
    END

    EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount

  COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()

    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0
    BEGIN
      ROLLBACK TRANSACTION
    END
    INSERT [mq].[SessionLog] ([SessionId], [SessionStateId], [ErrorMessage])
    SELECT COALESCE(@SessionId, (SELECT MAX([SessionId]) FROM [mq].[Session])),
      4,
      'Table MetaDataBuffer. Error: ' + @ErrorMessage

    IF NOT @ErrorMessage LIKE '%deadlock%'
      UPDATE b SET [IsError] = 1
      FROM [mq].[MetaDataBuffer] b
      INNER JOIN @tmp_metadata t ON b.[BufferId] = t.[BufferId]

    SET @RowCount = @@TRANCOUNT
    EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

    EXEC [audit].[sp_Print] @ErrorMessage, 4
    RETURN -1
  END CATCH
END
