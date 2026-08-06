CREATE PROCEDURE [odins].[load_DIM_Валюты_staging]
AS
BEGIN
DECLARE @LogID int, @ProcedureName varchar(510), @ProcedureParams varchar(max), @ProcedureInfo varchar(max), @AuditEnable nvarchar(256), @RowCount int
SET @AuditEnable = [audit].[fn_GetAuditEnableSP](N'AuditProcAll')
IF @AuditEnable IS NOT NULL 
BEGIN
  IF OBJECT_ID('tempdb..#LogProc') IS NULL
    SELECT * INTO #LogProc FROM [audit].[Template_LogProc]()
  SET @ProcedureName = '[odins].[load_DIM_Валюты_staging]'
  SET @ProcedureParams =''

  EXEC [audit].[sp_LogStart] @AuditEnable = @AuditEnable, @ProcedureName = @ProcedureName, @ProcedureParams = @ProcedureParams, @LogID = @LogID OUTPUT
END

  MERGE INTO [odins].[DIM_Валюты] trg
  USING 
  (
    SELECT *
    FROM [staging].[DIM_Валюты] p
    ) src
    ON src.[NKey] = trg.[NKey] 
    WHEN MATCHED 
    THEN UPDATE SET
      [NKey] = src.[NKey],
      [RefID] = src.[RefID],
      [DeletionMark] = src.[DeletionMark],
      [Code] = src.[Code],
      [Description] = src.[Description],
      [ЗагружаетсяИзИнтернета] = src.[ЗагружаетсяИзИнтернета],
      [НаименованиеПолное] = src.[НаименованиеПолное],
      [Наценка] = src.[Наценка],
      [ОсновнаяВалюта] = src.[ОсновнаяВалюта],
      [ПараметрыПрописи] = src.[ПараметрыПрописи],
      [ФормулаРасчетаКурса] = src.[ФормулаРасчетаКурса],
      [СпособУстановкиКурса] = src.[СпособУстановкиКурса],
      [UpdatedAt] = GetDate()
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      [NKey] ,
      [RefID],
      [DeletionMark],
      [Code],
      [Description],
      [ЗагружаетсяИзИнтернета],
      [НаименованиеПолное],
      [Наценка],
      [ОсновнаяВалюта],
      [ПараметрыПрописи],
      [ФормулаРасчетаКурса],
      [СпособУстановкиКурса],
      [UpdatedAt]
  )
    VALUES
  (
      src.[NKey] ,
      src.[RefID],
      src.[DeletionMark],
      src.[Code],
      src.[Description],
      src.[ЗагружаетсяИзИнтернета],
      src.[НаименованиеПолное],
      src.[Наценка],
      src.[ОсновнаяВалюта],
      src.[ПараметрыПрописи],
      src.[ФормулаРасчетаКурса],
      src.[СпособУстановкиКурса],
      src.[UpdatedAt]
  );


--Sub table
  DELETE FROM [odins].[DIM_Валюты.Представления];


  ;WITH XMLNAMESPACES (DEFAULT 'http://v8.1c.ru/8.1/data/enterprise/current-config')
  INSERT [odins].[DIM_Валюты.Представления] ([NKey], [DIM_ВалютыRefID], [КодЯзыка], [ПараметрыПрописи],  [UpdatedAt])  SELECT   [NKey] = CAST(SUBSTRING(HASHBYTES('SHA2_256', COALESCE(CAST(b.RefID AS varchar(36)), '00000000-0000-0000-0000-000000000000')+ 
    '|' + COALESCE(CAST(STR(LTRIM(ROW_NUMBER() OVER (PARTITION BY b.RefID ORDER BY b.Id))) AS varchar(36)), '00000000-0000-0000-0000-000000000000' ) )
      , 0,16) as uniqueidentifier),
  [DIM_ВалютыRefID] = b.RefID,
  [КодЯзыка] = X.C.value('(КодЯзыка/text())[1]', 'varchar(10)'),
  [ПараметрыПрописи] = X.C.value('(ПараметрыПрописи/text())[1]', 'varchar(200)'),
  [UpdatedAt]
  FROM staging.[DIM_Валюты] b
  CROSS APPLY b.[DIM_Валюты.Представления].nodes('/Представления') AS X(C);
SET @RowCount = @@ROWCOUNT
EXEC [audit].[sp_LogFinish] @LogID = @LogID, @RowCount = @RowCount
END

GO
