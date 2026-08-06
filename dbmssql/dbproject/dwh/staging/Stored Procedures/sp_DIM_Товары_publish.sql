CREATE PROCEDURE [staging].[sp_DIM_Товары_publish]
  @session_id bigint = NULL, 
  @RowCount bigint = NULL OUTPUT
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
  SET @ProcedureName = '[staging].[sp_DIM_Товары_publish]'
  SET @ProcedureParams =
    '@session_id=' + ISNULL(LTRIM(STR(@session_id)),'NULL')

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

DECLARE @ErrorMessage varchar(4000)
BEGIN TRY

  UPDATE trg SET
    trg.[session_id] = stg.[session_id],
    trg.[start_date] = stg.[start_date],
    trg.[end_date] = stg.[end_date],
    trg.[session_id_update] = stg.session_id_update,
    trg.[dt_update] = stg.dt_update,
    trg.[RefID] = stg.[RefID],
    trg.[DeletionMark] = stg.[DeletionMark],
    trg.[Code] = stg.[Code],
    trg.[Description] = stg.[Description],
    trg.[Описание] = stg.[Описание]
  FROM [staging].[DIM_Товары] stg
  INNER JOIN [target].[DIM_Товары] trg ON stg.id = trg.id

  INSERT [target].[DIM_Товары] (
    [id],
    [session_id],
    [source_name],
    [nkey],
    [vkey],
    [start_date],
    [end_date],
    [session_id_update],
    [dt_update],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [Описание]
  )
  SELECT
    [id],
    [session_id],
    [source_name],
    [nkey],
    [vkey],
    [start_date],
    [end_date],
    [session_id_update],
    [dt_update],
    [RefID],
    [DeletionMark],
    [Code],
    [Description],
    [Описание]
  FROM [staging].[DIM_Товары]
  WHERE staging_id = id
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
    [ErrorMessage] = 'Table [bulk].[odins_DIM_Товары]. Error: ' + @ErrorMessage

  EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount, @ErrorMessage = @ErrorMessage

  RAISERROR( N'Error: [%s].', 16, 1, @ErrorMessage)
  RETURN -1
END CATCH

END

GO
