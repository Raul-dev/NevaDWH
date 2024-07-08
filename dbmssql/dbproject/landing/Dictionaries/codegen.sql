DELETE [dbo].[codegen_dwh_column]
DELETE [dbo].[codegen_dwh_table]
DECLARE @codegen TABLE
(
    [codegen_id] int NOT NULL,
    [namespace] nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [schema] nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [table_name] nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [ods_enable_type] smallint NULL,
    [dwh_enable_type] smallint NULL
)



MERGE INTO codegen trg
USING 
@codegen src ON src.[codegen_id] = trg.[codegen_id]
WHEN MATCHED THEN UPDATE SET 
    [codegen_id] = src.[codegen_id],
    [namespace] = src.[namespace],
    [schema] = src.[schema],
    [table_name] = src.[table_name],
    [ods_enable_type] = src.[ods_enable_type],
    [dwh_enable_type] = src.[dwh_enable_type]
WHEN NOT MATCHED BY TARGET THEN 
INSERT ([codegen_id], [namespace], [schema], [table_name], [ods_enable_type], [dwh_enable_type])
    VALUES (
        src.[codegen_id],
        src.[namespace],
        src.[schema],
        src.[table_name],
        src.[ods_enable_type],
        src.[dwh_enable_type]
    )
WHEN NOT MATCHED BY SOURCE THEN DELETE;

--UPDATE [dbo].[codegen_dwh_table] SET [is_enable] = 1
--UPDATE [dbo].[codegen_dwh_column] SET [is_enable] = 1
