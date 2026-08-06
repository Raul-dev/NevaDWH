CREATE PROCEDURE [mq].[sp_SaveSessionState]
  @SessionId       bigint         = NULL,
  @DataSourceId    tinyint        = 1,
  @SessionStateId  tinyint        = 1,
  @ErrorMessage    varchar(4000)  = NULL
AS
SET CONCAT_NULL_YIELDS_NULL ON
  DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @RowCount int
  DECLARE @AuditEnable nvarchar(256)
  SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
  IF @AuditEnable IS NOT NULL
  BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
      SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
    SET @ProcedureName = '[mq].[sp_SaveSessionState]'
    SET @ProcedureParams =
      '@SessionId='+ISNULL(LTRIM(STR(@SessionId)),'NULL') + ', ' +
      '@DataSourceId='+ISNULL(LTRIM(STR(@DataSourceId)),'NULL') + ', ' +
      '@SessionStateId='+ISNULL(LTRIM(STR(@SessionStateId)),'NULL')

    EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
  END

  IF (@SessionId IS NULL)
  BEGIN
    DECLARE @IdentityOutput TABLE ([SessionId] bigint)

    INSERT [mq].[Session] ([DataSourceId], [SessionStateId], [ErrorMessage])
    OUTPUT inserted.[SessionId] INTO @IdentityOutput
    VALUES (@DataSourceId, @SessionStateId, @ErrorMessage)

    INSERT [mq].[SessionLog] ([SessionId], [SessionStateId], [ErrorMessage])
    SELECT [SessionId], @SessionStateId, @ErrorMessage FROM @IdentityOutput

    SELECT [SessionId] FROM @IdentityOutput
  END
  ELSE
  BEGIN
    UPDATE [mq].[Session]
    SET [SessionStateId] = @SessionStateId,
      [ErrorMessage]   = @ErrorMessage,
      [UpdatedAt]      = SYSDATETIME()
    WHERE [SessionId] = @SessionId

    INSERT [mq].[SessionLog] ([SessionId], [SessionStateId], [ErrorMessage])
    VALUES (@SessionId, @SessionStateId, @ErrorMessage)
  END

  SET @RowCount = @@ROWCOUNT
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
