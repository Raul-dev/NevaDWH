  CREATE PROCEDURE [etl].[dwh_ArchiveTables]
  @DwhSessionId bigint = NULL,
  @ErrorMessage nvarchar(4000) = NULL OUTPUT
AS
BEGIN
BEGIN TRY
  SET CONCAT_NULL_YIELDS_NULL ON
  DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @AuditEnable nvarchar(256), @RowCount int
  SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
  IF @AuditEnable IS NOT NULL
  BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
      SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
    SET @ProcedureName = '[etl].[dwh_ArchiveTables]'
    SET @ProcedureParams = '@DwhSessionId='+ISNULL(LTRIM(STR(@DwhSessionId)),'NULL')
    EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
  END

  BEGIN TRANSACTION

    UPDATE [etl].[DwhSession] SET [DwhSessionStateId] = 6
    WHERE [DwhSessionId] = @DwhSessionId
  COMMIT TRANSACTION
  IF @ErrorMessage IS NULL SET @ErrorMessage = ''
END TRY
BEGIN CATCH
  SELECT @ErrorMessage = ERROR_MESSAGE()

  IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0
  BEGIN
    ROLLBACK TRANSACTION
  END

  INSERT [etl].[DwhSessionLog] ([DwhSessionId], [DwhSessionStateId], [ErrorMessage])
  SELECT @DwhSessionId, 3, 'ArchiveTables Error: ' + @ErrorMessage

  IF XACT_STATE() != -1
   BEGIN
    IF (@@TRANCOUNT > 0 ) ROLLBACK TRANSACTION
   END

  RAISERROR(N'Error: [%s].', 16, 1, @ErrorMessage)
  RETURN -1
END CATCH
END
