DECLARE @codegen_enable_type AS TABLE
(
  [CodeGenEnableTypeId] TINYINT,
  [Description]         NVARCHAR(100)
)

INSERT @codegen_enable_type ([CodeGenEnableTypeId], [Description]) VALUES
(0, N'Исключить из проекта ODS'),
(1, N'Генерировать код ODS если файлы отсутствуют'),
(2, N'Генерировать только ODS таблицы всегда , процедуры только если отсутствуют'),
(3, N'Генерировать код ODS')

IF EXISTS (
  SELECT 1 FROM [etl].[CodeGenEnableType] d
  LEFT OUTER JOIN @codegen_enable_type s ON s.[CodeGenEnableTypeId] = d.[CodeGenEnableTypeId]
  WHERE s.[CodeGenEnableTypeId] IS NULL) THROW 60000, N'The table [etl].[CodeGenEnableType] was change.', 1;

MERGE INTO [etl].[CodeGenEnableType] trg
USING @codegen_enable_type src ON src.[CodeGenEnableTypeId] = trg.[CodeGenEnableTypeId]
WHEN MATCHED THEN UPDATE SET [Description] = src.[Description]
WHEN NOT MATCHED BY TARGET THEN
  INSERT ([CodeGenEnableTypeId], [Description]) VALUES (src.[CodeGenEnableTypeId], src.[Description])
WHEN NOT MATCHED BY SOURCE THEN DELETE;
