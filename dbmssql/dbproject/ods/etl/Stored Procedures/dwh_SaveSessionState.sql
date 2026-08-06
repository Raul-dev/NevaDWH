
CREATE PROCEDURE [etl].[dwh_SaveSessionState]
  @DwhSessionId       bigint         = NULL,
  @DataSourceId       tinyint        = 1,
  @DwhSessionStateId  tinyint        = 1,
  @ErrorMessage       varchar(4000)  = NULL
AS
  SET CONCAT_NULL_YIELDS_NULL ON
  DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @AuditEnable nvarchar(256), @RowCount int
  SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
  IF @AuditEnable IS NOT NULL
  BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
      SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
    SET @ProcedureName = '[etl].[dwh_SaveSessionState]'
    SET @ProcedureParams =
      '@DwhSessionId='+ISNULL(LTRIM(STR(@DwhSessionId)),'NULL') + ', ' +
      '@DataSourceId='+ISNULL(LTRIM(STR(@DataSourceId)),'NULL') + ', ' +
      '@DwhSessionStateId='+ISNULL(LTRIM(STR(@DwhSessionStateId)),'NULL')
    EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
  END

  IF (@DwhSessionId IS NULL)
  BEGIN
    SELECT @DwhSessionId = MAX([DwhSessionId]) FROM [etl].[DwhSession] WHERE [DwhSessionStateId] = 1

    IF (NOT @DwhSessionId IS NULL)
    BEGIN
      SELECT @DwhSessionId AS DwhSessionId
      RETURN;
    END

    DECLARE @IdentityOutput TABLE ([DwhSessionId] bigint)
    INSERT [etl].[DwhSession] ([DataSourceId], [DwhSessionStateId], [ErrorMessage])
    OUTPUT inserted.[DwhSessionId] INTO @IdentityOutput
    VALUES (@DataSourceId, @DwhSessionStateId, @ErrorMessage)
    SELECT [DwhSessionId] FROM @IdentityOutput
  END
  ELSE
  BEGIN
    UPDATE [etl].[DwhSession]
    SET [CreateSession] = CASE WHEN @DwhSessionStateId = 2 THEN SYSDATETIME() ELSE [CreateSession] END,
      [DwhSessionStateId] = @DwhSessionStateId,
      [ErrorMessage] = @ErrorMessage,
      [UpdatedAt] = SYSDATETIME()
    WHERE [DwhSessionId] = @DwhSessionId
  END

  SET @RowCount = @@ROWCOUNT
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
