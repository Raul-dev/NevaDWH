CREATE PROCEDURE [dbo].[sp_SaveSessionState] 
    @session_id        bigint = NULL,
    @dwh_session_id    bigint = NULL,
    @rows_count        int = NULL,
    @data_source_id    tinyint = 1,
    @session_state_id  tinyint = 1,
    @create_session    datetime2(4) = NULL,
    @error_message     varchar(4000) = NULL
AS
    DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
    SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
    IF @AuditProcEnable IS NOT NULL 
    BEGIN
        IF OBJECT_ID('tempdb..#LogProc') IS NULL
            CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
        SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'                        
        SET @ProcedureParams =
        '@session_id='+ISNULL(LTRIM(STR(@session_id)),'NULL') + ' ' +
        '@dwh_session_id='+ISNULL(LTRIM(STR(@dwh_session_id)),'NULL') + ' ' +
        '@rows_count='+ISNULL(LTRIM(STR(@rows_count)),'NULL') + ' ' +
        '@data_source_id='+ISNULL(LTRIM(STR(@data_source_id)),'NULL') + ' ' +
        '@session_state_id='+ISNULL(LTRIM(STR(@session_state_id)),'NULL') + ' ' +
        '@create_session='+ISNULL('''' +CAST(@create_session AS varchar(19) ) + '''','NULL') + ' ' +
        '@error_message='+ISNULL('''' + @error_message + '''','NULL')

        EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
    END
    
    IF(@session_id IS NULL)
    BEGIN
        DECLARE @IdentityOutput table (session_id bigint )
        INSERT [session] ([dwh_session_id], [rows_count], [data_source_id], [session_state_id], [create_session], [error_message])
        OUTPUT inserted.[session_id] into @IdentityOutput
        VALUES(@dwh_session_id, @rows_count, @data_source_id, @session_state_id, @create_session, @error_message)
        SELECT * FROM @IdentityOutput
    END 
    ELSE
    BEGIN
        UPDATE [session] SET 
            [session_state_id] = @session_state_id,    
            [error_message]    = @error_message,
            [dt_update]        = GetDate()
        WHERE [session_id] = @session_id
    END
    SET @RowCount = @@ROWCOUNT
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount
