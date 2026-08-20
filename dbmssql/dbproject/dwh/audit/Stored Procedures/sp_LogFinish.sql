
CREATE PROCEDURE [audit].[sp_LogFinish]
  @LogID          int            = NULL,
  @RowCount       int            = NULL,
  @ProcedureInfo  varchar(max)   = NULL,
  @ErrorMessage   varchar(4000)  = NULL
AS
BEGIN
  SET NOCOUNT ON
  IF @LogID IS NULL RETURN 0

  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()

  DECLARE
    @EndTime     datetime2(4) = GetDate(),
    @TranCount   int          = @@TRANCOUNT,
    @AuditTypeID tinyint,
    @UseLnk      bit

  SELECT @AuditTypeID = AuditTypeID FROM #LogProc WHERE LogID = @LogID
  IF @AuditTypeID IS NULL OR @AuditTypeID = 0 RETURN 0

  SET @UseLnk = [audit].[fn_log_IsLnk]()

  IF @AuditTypeID = 1 AND @UseLnk = 1
    EXEC [$(LinkSRVLogLanding)].[$(dwh)].[audit].sp_LnkUpdate
      @LogID         = @LogID,
      @EndTime       = @EndTime,
      @RowCount      = @RowCount,
      @TranCount     = @TranCount,
      @ProcedureInfo = @ProcedureInfo,
      @ErrorMessage  = @ErrorMessage

  IF @AuditTypeID = 1 AND @UseLnk = 0
    EXEC [audit].sp_LnkUpdate
      @LogID         = @LogID,
      @EndTime       = @EndTime,
      @RowCount      = @RowCount,
      @TranCount     = @TranCount,
      @ProcedureInfo = @ProcedureInfo,
      @ErrorMessage  = @ErrorMessage

  IF @AuditTypeID = 2 AND @UseLnk = 1
    EXEC [$(LinkSRVLog)].[$(log)].[audit].sp_LnkUpdate
      @LogID         = @LogID,
      @EndTime       = @EndTime,
      @RowCount      = @RowCount,
      @TranCount     = @TranCount,
      @ProcedureInfo = @ProcedureInfo,
      @ErrorMessage  = @ErrorMessage

  IF @AuditTypeID = 2 AND @UseLnk = 0
    EXEC [audit].sp_LnkUpdate
      @LogID         = @LogID,
      @EndTime       = @EndTime,
      @RowCount      = @RowCount,
      @TranCount     = @TranCount,
      @ProcedureInfo = @ProcedureInfo,
      @ErrorMessage  = @ErrorMessage

  DELETE FROM #LogProc WHERE LogID >= @LogID
END
