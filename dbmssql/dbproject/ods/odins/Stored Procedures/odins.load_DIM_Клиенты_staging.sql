CREATE PROCEDURE [odins].[load_DIM_Клиенты_staging]
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256), @RowCount int
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[odins].[load_DIM_Клиенты_staging]'
  SET @ProcedureParams =''

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

  MERGE INTO [odins].[DIM_Клиенты] trg
  USING 
  (
    SELECT *
    FROM [staging].[DIM_Клиенты] p
    ) src
    ON src.[NKey] = trg.[NKey] 
    WHEN MATCHED 
    THEN UPDATE SET
      [NKey] = src.[NKey],
      [RefID] = src.[RefID],
      [DeletionMark] = src.[DeletionMark],
      [Code] = src.[Code],
      [Description] = src.[Description],
      [Контакт] = src.[Контакт],
      [UpdatedAt] = GetDate()
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      [NKey] ,
      [RefID],
      [DeletionMark],
      [Code],
      [Description],
      [Контакт],
      [UpdatedAt]
  )
    VALUES
  (
      src.[NKey] ,
      src.[RefID],
      src.[DeletionMark],
      src.[Code],
      src.[Description],
      src.[Контакт],
      src.[UpdatedAt]
  );


--Sub table
SET @RowCount = @@ROWCOUNT
EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
END

GO
