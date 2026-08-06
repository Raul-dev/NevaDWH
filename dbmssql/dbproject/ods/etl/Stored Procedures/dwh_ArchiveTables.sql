  CREATE PROCEDURE [etl].[dwh_ArchiveTables]( 
  @DwhSessionId bigint = NULL,
  @ErrorMessage   varchar(4000) = NULL OUTPUT
)
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256), @RowCount int
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[etl].[dwh_ArchiveTables]'
  SET @ProcedureParams =
    '@DwhSessionId=' + ISNULL(LTRIM(STR(@DwhSessionId)),'NULL')

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END
BEGIN TRY

  BEGIN TRANSACTION

  DELETE [odins].[DIM_Валюты_history] WHERE [DwhSessionId] = @DwhSessionId

  DELETE [odins].[DIM_Валюты.Представления_history] WHERE [DwhSessionId] = @DwhSessionId

  DELETE [odins].[DIM_Клиенты_history] WHERE [DwhSessionId] = @DwhSessionId

  DELETE [odins].[DIM_Товары_history] WHERE [DwhSessionId] = @DwhSessionId

  DELETE [odins].[FACT_Продажи_history] WHERE [DwhSessionId] = @DwhSessionId

  DELETE [odins].[FACT_Продажи.Товары_history] WHERE [DwhSessionId] = @DwhSessionId


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
  SELECT @DwhSessionId,
    [DwhSessionStateId] = 3,
    [ErrorMessage] = 'ArchiveTables Error: ' + @ErrorMessage
  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

  RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
  RETURN -1
END CATCH
END

