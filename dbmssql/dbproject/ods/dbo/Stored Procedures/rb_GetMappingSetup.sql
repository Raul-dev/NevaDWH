CREATE   PROCEDURE [dbo].[rb_GetMappingSetup]
AS
    SET CONCAT_NULL_YIELDS_NULL ON
    DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
    SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
    IF @AuditProcEnable IS NOT NULL 
    BEGIN
        IF OBJECT_ID('tempdb..#LogProc') IS NULL
            CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
        SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'                        
        SET @ProcedureParams =''
        EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
    END
    SELECT 
        metamap_id,
        msg_key,
        table_name,
        metaadapter_id,
        etl_query
    FROM [metamap] WHERE is_enable = 1
    EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount