CREATE PROCEDURE [etl].[dwh_AssignSessionID]
  @DwhSessionId  bigint         = NULL OUTPUT,
  @RowCount      int            = NULL OUTPUT,
  @ErrorMessage  varchar(4000)  = NULL OUTPUT
AS
BEGIN
  SET CONCAT_NULL_YIELDS_NULL ON
  DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @AuditEnable nvarchar(256)
  SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
  IF @AuditEnable IS NOT NULL
  BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
      SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
    SET @ProcedureName = '[etl].[dwh_AssignSessionID]'
    SET @ProcedureParams = '@DwhSessionId='+ISNULL(LTRIM(STR(@DwhSessionId)),'NULL')
    EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
  END

SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET DEADLOCK_PRIORITY HIGH
BEGIN TRY
  SET @RowCount = 0
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
  SELECT @DwhSessionId, 3, 'AssignSessionID Error: ' + @ErrorMessage

  SET @RowCount = @@TRANCOUNT
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

  SELECT @DwhSessionId, -1 AS [RowCount], @ErrorMessage AS [ErrMessage]
  RETURN -1
END CATCH

END

GO
