CREATE PROCEDURE [odins].[load_DIM_Товары_staging]
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256), @RowCount int
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[odins].[load_DIM_Товары_staging]'
  SET @ProcedureParams =''

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

  MERGE INTO [odins].[DIM_Товары] trg
  USING 
  (
    SELECT *
    FROM [staging].[DIM_Товары] p
    ) src
    ON src.[NKey] = trg.[NKey] 
    WHEN MATCHED 
    THEN UPDATE SET
      [NKey] = src.[NKey],
      [RefID] = src.[RefID],
      [DeletionMark] = src.[DeletionMark],
      [Code] = src.[Code],
      [Description] = src.[Description],
      [Описание] = src.[Описание],
      [UpdatedAt] = GetDate()
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      [NKey] ,
      [RefID],
      [DeletionMark],
      [Code],
      [Description],
      [Описание],
      [UpdatedAt]
  )
    VALUES
  (
      src.[NKey] ,
      src.[RefID],
      src.[DeletionMark],
      src.[Code],
      src.[Description],
      src.[Описание],
      src.[UpdatedAt]
  );


--Sub table
SET @RowCount = @@ROWCOUNT
EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
END

GO
