

CREATE PROCEDURE [audit].[sp_AuditFinish] 
    @LogID        int = NULL,    
    @RecordCount    int = NULL,
    @SPInfo        varchar(MAX) = NULL
AS 
BEGIN
    SET NOCOUNT ON 
    DECLARE @AuditProcEnable nvarchar(128)
    SELECT @AuditProcEnable =  [dbo].[fn_GetSettingValue]('AuditProcAll')
    IF @AuditProcEnable is NULL
        RETURN 0
    IF object_id(N'tempdb.dbo.#AuditProc') IS NULL
        CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)

    DECLARE @TranCount int 
    SET @TranCount = @@TRANCOUNT

    UPDATE [audit].[LogProcedures]
    SET [EndTime]  = GETDATE(),
        [Duration] = DATEDIFF(ms, [StartTime], GETDATE()),
        [RowCount] = @RecordCount,
        [SPInfo]   = ISNULL([SPInfo], '')
                     + CASE WHEN [TransactionCount] = @TranCount THEN '' 
                       ELSE 'Tran count changed to ' + ISNULL(LTRIM(STR(@TranCount, 10, 0)), 'NULL') + ';' END
                     + CASE WHEN @SPInfo IS NULL THEN ''
                       ELSE 'Finish:' + CONVERT(varchar(19), GETDATE(), 120) + ':' + @SPInfo + ';' END                       
    WHERE [LogID] = @LogID

    DELETE FROM #AuditProc WHERE LogID >= @LogID
END