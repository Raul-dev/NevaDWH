
/*
BEGIN TRAN
DECLARE @LogID int
EXEC [audit].sp_LogStart @AuditEnable ='AuditProcAll', @LogID = @LogID output
SELECT @LogID

SELECT * FROM [audit].[LogProcedures]
ROLLBACK

*/

CREATE PROCEDURE [audit].[sp_LogStart]
  @AuditEnable  nvarchar(256)  = NULL,
  @ProcedureName    varchar(512)   = NULL,
  @ProcedureParams  varchar(max)   = NULL,
  @LogID            int            = NULL OUTPUT

AS
BEGIN
  SET NOCOUNT ON
  DECLARE @AuditTypeID tinyint, @UseLnk bit
  SELECT @AuditTypeID = [audit].[fn_GetAuditTypeSP](@AuditEnable)

  IF @AuditTypeID IS NULL OR @AuditTypeID = 0
    RETURN 0

  SET @UseLnk = [audit].[fn_log_IsLnk]()

  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()

  DECLARE
    @ParentID    int,
    @MainID      int,
    @CountIds    int,
    @StartTime   datetime2(4)  = GetDate(),
    @SysDbName   nvarchar(128) = DB_NAME(),
    @SysUserName varchar(256)  = original_login(),
    @SysHostName varchar(128)  = CAST(@@SERVERNAME as varchar(100)),
    @SysAppName  varchar(128)  = app_name()

  SELECT @MainID    = MIN(LogID),
     @ParentID  = MAX(LogID),
     @CountIds  = COUNT(LogID)
  FROM #LogProc

  SET @ProcedureName = LEFT(REPLICATE('  ', @CountIds) + LTRIM(RTRIM(@ProcedureName)), 512)

  IF @AuditTypeID = 1 AND @UseLnk = 1
    EXEC [$(LinkSRVLogLanding)].[$(landing)].[audit].sp_LnkInsert
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

  IF @AuditTypeID = 1 AND @UseLnk = 0
    EXEC [audit].sp_LnkInsert
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

  IF @AuditTypeID = 2 AND @UseLnk = 1
    EXEC [$(LinkSRVLog)].[$(log)].[audit].sp_LnkInsert
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

  IF @AuditTypeID = 2 AND @UseLnk = 0
    EXEC [audit].sp_LnkInsert
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
    INSERT #LogProc(LogID, AuditTypeID) VALUES(ISNULL(@LogID, 0), @AuditTypeID)

END
