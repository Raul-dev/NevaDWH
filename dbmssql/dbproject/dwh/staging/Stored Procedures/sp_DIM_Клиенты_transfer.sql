CREATE PROCEDURE [staging].[sp_DIM_Клиенты_transfer]
  @session_id bigint = NULL, 
  @RowCount   bigint = NULL OUTPUT
AS
BEGIN
SET XACT_ABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET NOCOUNT ON
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256)
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[staging].[sp_DIM_Клиенты_transfer]'
  SET @ProcedureParams =
    '@session_id=' + ISNULL(LTRIM(STR(@session_id)),'NULL')

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

DECLARE @ErrorMessage varchar(4000)
BEGIN TRY
  DECLARE @start_date datetime
  DECLARE @dwh_session_id bigint, @LastTargetID bigint, @LocalCount bigint
  DECLARE @source_name varchar(128) 

  TRUNCATE TABLE [staging].[DIM_Клиенты]
  SELECT @LastTargetID = MAX(id) FROM [target].[DIM_Клиенты]
  IF ISNULL(@LastTargetID,0) >= 1
  BEGIN
    SET @LastTargetID = @LastTargetID + 1
    DBCC CHECKIDENT('[staging].[DIM_Клиенты]', RESEED, @LastTargetID) WITH NO_INFOMSGS
  END

  SELECT @start_date = s.[CreatedAt],
    @dwh_session_id = s.[DwhSessionId],
    @source_name = (SELECT [Name] FROM [mq].[DataSource] d WHERE d.[DataSourceId] = s.[DataSourceId])
  FROM [mq].[Session] s WHERE s.[SessionId] = @session_id

  INSERT [staging].[DIM_Клиенты] (
    [session_id],
    [source_name],
    [nkey],
    [vkey],
    [start_date],
    [end_date],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [Контакт],
    [session_id_update],
    [dt_update]
  )
  SELECT
    @session_id AS [session_id],
    @source_name AS [source_name],
    tmp.[NKey],
    tmp.[NKey] AS [vkey],
    @start_date AS [start_date],
    mq.fn_GetMaxDate() AS [end_date],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [Контакт],
    @session_id AS [session_id_update],
    @start_date AS [dt_update]
  FROM [$(LinkSRVOds)].[$(ods)].[odins].[DIM_Клиенты_history] tmp
  WHERE tmp.[DwhSessionId] = @dwh_session_id
  SET @LocalCount= ROWCOUNT_BIG ( ) 
  SELECT @RowCount = @RowCount + @LocalCount

  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
END TRY
BEGIN CATCH
  SELECT @ErrorMessage = ERROR_MESSAGE()
  IF XACT_STATE() <> 0 AND @@TRANCOUNT > 0 
  BEGIN
    ROLLBACK TRANSACTION
  END

  INSERT [mq].[SessionLog] ([SessionId], [SessionStateId], [ErrorMessage])
  SELECT [SessionId] = @session_id,
    [SessionStateId] = 3,
    [ErrorMessage] = 'ETL transfer [odins_DIM_Клиенты]. Error: ' +@ErrorMessage

  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

  RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
  RETURN -1
END CATCH

END

GO
