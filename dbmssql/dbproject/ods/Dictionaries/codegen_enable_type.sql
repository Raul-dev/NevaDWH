DECLARE @codegen_enable_type AS TABLE
(
    [codegen_enable_type_id] TINYINT,
    [description] NVARCHAR(100)
)

INSERT @codegen_enable_type ([codegen_enable_type_id], [description]) VALUES
(0, N'Исключить из проекта ODS'),
(1, N'Генерировать код ODS если файлы отсутствуют'), --First Generation
(2, N'Генерировать только ODS таблицы всегда , процедуры только если отсутствуют'),
(3, N'Генерировать код ODS')


IF EXISTS ( 
    SELECT 1 FROM [dbo].[codegen_enable_type] d 
    LEFT OUTER JOIN @codegen_enable_type s ON s.codegen_enable_type_id=d.codegen_enable_type_id
    WHERE s.codegen_enable_type_id IS NULL) THROW 60000, N'The tablle [codegen_enable_type] was change.', 1;

MERGE INTO [dbo].[codegen_enable_type] trg
USING 
@codegen_enable_type src ON src.[codegen_enable_type_id] = trg.[codegen_enable_type_id]
WHEN MATCHED THEN UPDATE SET 
    [description] = src.[description]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT ([codegen_enable_type_id] , [description]) VALUES (src.[codegen_enable_type_id] , src.[description])
WHEN NOT MATCHED BY SOURCE THEN DELETE;