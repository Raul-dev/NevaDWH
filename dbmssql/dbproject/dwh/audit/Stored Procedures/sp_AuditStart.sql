

/*
    DECLARE @ID int 
    EXEC audit.sp_AuditStart @ID = @ID output
    SELECT @ID
    SELECT [meta].[ufn_GetConfigValue]('AuditProcAll')
*/

CREATE PROCEDURE [audit].[sp_AuditStart]    
    @SPName varchar(512) = NULL,
    @SPParams varchar(MAX) = NULL,
    @SPSub  varchar(256) = NULL,        
    @LogID int OUTPUT       
AS 
BEGIN
    SET NOCOUNT ON 
    DECLARE @AuditProcEnable nvarchar(128)
    SELECT @AuditProcEnable =  [dbo].[fn_GetSettingValue]('AuditProcAll')
    IF @AuditProcEnable is NULL
        RETURN 0

    IF object_id(N'tempdb.dbo.#AuditProc') IS NULL
        CREATE TABLE #AuditProc(LogID int Primary Key NOT NULL)

    DECLARE @ParentID int 
    DECLARE @MainID int 
    DECLARE @CountIds int 
    DECLARE @TranCount int 
    SET @TranCount = @@TRANCOUNT 
    
    SELECT @MainID  =   MIN(LogID), 
        @ParentID   =   MAX(LogID), 
        @CountIds   = COUNT(LogID) 
    FROM #AuditProc

    SET @SPName = LEFT(REPLICATE('    ', @CountIds) + LTRIM(RTRIM(@SPName)), 512) + ISNULL(': ' + @SPSub, '')

    INSERT [audit].[LogProcedures] ([MainID], [ParentID], [SPName], [SPParams], [TransactionCount])
    VALUES(@MainID, @ParentID, @SPName, @SPParams, @TranCount)
    SET @LogID  = SCOPE_IDENTITY()
    
    IF @MainID IS NULL 
        UPDATE [audit].[LogProcedures]
            SET [MainID] = @LogID
        WHERE LogID = @LogID

    IF @ParentID IS NULL OR @ParentID < @LogID 
        INSERT #AuditProc(LogID) VALUES(@LogID)                    
END
