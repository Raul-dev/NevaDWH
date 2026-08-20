CREATE PROCEDURE [audit].[sp_LogInfo]
  @LogID          int           = NULL,
  @ProcedureInfo  varchar(max)  = NULL
AS
BEGIN

  IF @LogID IS NULL RETURN 0

  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()

  DECLARE @AuditTypeID tinyint, @UseLnk bit
  SELECT @AuditTypeID = AuditTypeID FROM #LogProc WHERE LogID = @LogID
  IF @AuditTypeID IS NULL OR @AuditTypeID = 0 RETURN 0

  SET @UseLnk = [audit].[fn_log_IsLnk]()

  IF @AuditTypeID = 1 AND @UseLnk = 1
    EXEC [$(LinkSRVLogLanding)].[$(dwh)].[audit].sp_LnkUpdate
      @LogID         = @LogID,
      @ProcedureInfo = @ProcedureInfo

  IF @AuditTypeID = 1 AND @UseLnk = 0
    EXEC [audit].sp_LnkUpdate
      @LogID         = @LogID,
      @ProcedureInfo = @ProcedureInfo

  IF @AuditTypeID = 2 AND @UseLnk = 1
    EXEC [$(LinkSRVLog)].[$(log)].[audit].sp_LnkUpdate
      @LogID         = @LogID,
      @ProcedureInfo = @ProcedureInfo

  IF @AuditTypeID = 2 AND @UseLnk = 0
    EXEC [audit].sp_LnkUpdate
      @LogID         = @LogID,
      @ProcedureInfo = @ProcedureInfo

  RETURN 0
END
