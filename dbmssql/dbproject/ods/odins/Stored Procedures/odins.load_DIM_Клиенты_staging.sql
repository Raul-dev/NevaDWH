CREATE PROCEDURE [odins].[load_DIM_Клиенты_staging]
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditProcEnable nvarchar(256), @RowCount int
SET @AuditProcEnable = [dbo].[fn_GetSettingValue]('AuditProcAll')
IF @AuditProcEnable IS NOT NULL 
BEGIN
    IF OBJECT_ID('tempdb..#LogProc') IS NULL
        CREATE TABLE #LogProc(LogID int Primary Key NOT NULL)
    SET @ProcedureName = '[' + OBJECT_SCHEMA_NAME(@@PROCID)+'].['+OBJECT_NAME(@@PROCID)+']'
    SET @ProcedureParams =''

    EXEC [audit].[sp_log_Start] @AuditProcEnable = @AuditProcEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

    MERGE INTO [odins].[DIM_Клиенты] trg
    USING 
    (
        SELECT *
        FROM [staging].[DIM_Клиенты] p
         ) src
        ON src.[nkey] = trg.[nkey] 
         WHEN MATCHED 
        THEN UPDATE SET
            [nkey] = src.[nkey],
            [RefID] = src.[RefID],
            [DeletionMark] = src.[DeletionMark],
            [Code] = src.[Code],
            [Description] = src.[Description],
            [Контакт] = src.[Контакт],
            [dt_update] = GetDate()
        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            [nkey] ,
            [RefID],
            [DeletionMark],
            [Code],
            [Description],
            [Контакт],
            [dt_update]
    )
        VALUES
    (
            src.[nkey] ,
            src.[RefID],
            src.[DeletionMark],
            src.[Code],
            src.[Description],
            src.[Контакт],
            [dt_update]
     );


--Sub table
SET @RowCount = @@ROWCOUNT
EXEC [audit].[sp_log_Finish] @LogID = @LogID, @RowCount = @RowCount
END

GO
