
CREATE PROCEDURE [dbo].[dwh_SaveSessionState] 
    @dwh_session_id       bigint = NULL,
    @data_source_id       tinyint = 1,
    @dwh_session_state_id tinyint = 1,
    @error_message        varchar(4000) = NULL
AS
    SET CONCAT_NULL_YIELDS_NULL ON
    DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
    SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
    IF @AuditProcEnable IS NOT NULL 
    BEGIN
        IF OBJECT_ID('tempdb..#LogProc') IS NULL
            CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
        SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'                        
        SET @ProcedureParams =
            '@dwh_session_id='+ISNULL(LTRIM(STR(@dwh_session_id)),'NULL')  + ', ' +
            '@data_source_id='+ISNULL(LTRIM(STR(@data_source_id)),'NULL') + ', ' +
            '@dwh_session_state_id='+ISNULL(LTRIM(STR(@dwh_session_state_id)),'NULL')
        EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
    END

    IF(@dwh_session_id IS NULL)
    BEGIN
        SELECT @dwh_session_id = MAX(dwh_session_id) FROM [dwh_session] WHERE dwh_session_state_id = 1
        
        IF(NOT @dwh_session_id IS NULL)
        BEGIN
            SELECT @dwh_session_id AS dwh_session_id
            RETURN;
        END
    
        DECLARE @IdentityOutput table ( dwh_session_id int )
        INSERT [dwh_session] ([data_source_id],    [dwh_session_state_id],    [error_message])
        OUTPUT inserted.dwh_session_id into @IdentityOutput
        VALUES(@data_source_id, @dwh_session_state_id, @error_message)
        SELECT * FROM @IdentityOutput
    END 
    ELSE
    BEGIN
        UPDATE [dwh_session] 
            SET 
                [create_session]       = CASE WHEN @dwh_session_state_id = 2 THEN GetDate() ELSE [create_session] END,
                [dwh_session_state_id] = @dwh_session_state_id,    
                [error_message]        = @error_message,
                [dt_update]            = GetDate()
        WHERE dwh_session_id = @dwh_session_id
    END

    SET @RowCount = @@TRANCOUNT
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount
