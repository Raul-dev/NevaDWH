/*
BEGIN TRAN
DECLARE @LogID int 
EXEC [audit].sp_log_Start @AuditProcEnable ='AuditProcEnable', @LogID = @LogID output
SELECT @LogID

SELECT [dbo].[fn_GetSettingValue]('AuditProcAll')
SELECT * FROM [audit].[LogProcedures]
ROLLBACk

*/

CREATE PROCEDURE [audit].[sp_log_Start]   
    @AuditProcEnable nvarchar(256) = NULL,
    @ProcedureName   varchar(512)  = NULL,
    @ProcedureParams varchar(MAX)  = NULL,
    @LogID           int           = NULL OUTPUT
    
AS 
BEGIN
    SET NOCOUNT ON 
    IF @AuditProcEnable is NULL
        RETURN 0
        
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
                
    DECLARE 
        @ParentID    int, 
        @MainID      int, 
        @CountIds    int, 
        @StartTime   datetime2(4)  = GetDate(),  
        @SysDbName   nvarchar(128) = DB_NAME(),
        @SysUserName varchar(256)  = original_login(),
        @SysHostName varchar(128)  = CAST(@@SERVERNAME as varchar(100)),
        @SysAppName  varchar(128)  = app_name()

    SELECT @MainID    =   MIN(LogID), 
           @ParentID  =   MAX(LogID), 
           @CountIds  = COUNT(LogID) 
    FROM #LogProc
        
    SET @ProcedureName = LEFT(REPLICATE('  ', @CountIds) + LTRIM(RTRIM(@ProcedureName)), 512)

    EXEC [$(LinkSRVLogLanding)].[$(landing)].[audit].sp_lnk_Insert
        @MainID           = @MainID,
        @ParentID         = @ParentID,
        @StartTime        = @StartTime,
        @SysUserName      = @SysUserName,
        @SysHostName      = @SysHostName,
        @SysDbName        = @SysDbName,
        @SysAppName       = @SysAppName,
        @SPID             = @@SPID,
        @ProcedureName    = @ProcedureName,
        @ProcedureParams  = @ProcedureParams,
        @TransactionCount = @@TRANCOUNT,
        @LogID            = @LogID OUTPUT

    IF @ParentID IS NULL OR @ParentID < @LogID 
        INSERT #LogProc(LogID) VALUES(@LogID)   

END