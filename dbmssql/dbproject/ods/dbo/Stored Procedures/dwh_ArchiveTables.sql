 CREATE PROCEDURE dwh_ArchiveTables( 
    @dwh_session_id bigint = NULL,
    @ErrorMessage   varchar(4000) = NULL OUTPUT
)
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
    SET @ProcedureParams =
        '@dwh_session_id=' + ISNULL(LTRIM(STR(@dwh_session_id)),'NULL')

    EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END
BEGIN TRY

    BEGIN TRANSACTION

    DELETE [odins].[DIM_Валюты_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[DIM_Валюты.Представления_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[DIM_Клиенты_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[DIM_Товары_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[FACT_Продажи_history] WHERE dwh_session_id = @dwh_session_id

    DELETE [odins].[FACT_Продажи.Товары_history] WHERE dwh_session_id = @dwh_session_id


    UPDATE [dwh_session] SET dwh_session_state_id = 6
    WHERE dwh_session_id = @dwh_session_id
    COMMIT TRANSACTION
    IF @ErrorMessage IS NULL SET @ErrorMessage = ''
END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE()

    IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
    BEGIN
         ROLLBACK TRANSACTION
    END

    INSERT [dwh_session_log] ( dwh_session_id, [dwh_session_state_id], [error_message])
    SELECT dwh_session_id = @dwh_session_id,
        [dwh_session_state_id] = 3,
        [error_message] = 'ArchiveTables Error: ' + @ErrorMessage
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

    RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
    RETURN -1
END CATCH
END

