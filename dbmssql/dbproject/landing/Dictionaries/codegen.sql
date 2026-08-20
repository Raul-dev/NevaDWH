DELETE [etl].[CodeGenDwhColumn]
DELETE [etl].[CodeGenDwhTable]

DECLARE @codegen TABLE
(
  [CodeGenId]       int NOT NULL,
  [Namespace]       nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
  [SchemaName]      nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
  [TableName]       nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
  [OdsEnableType]   smallint NULL,
  [DwhEnableType]   smallint NULL
)

MERGE INTO [etl].[CodeGen] trg
USING @codegen src ON src.[CodeGenId] = trg.[CodeGenId]
WHEN MATCHED THEN UPDATE SET
  [CodeGenId]       = src.[CodeGenId],
  [Namespace]       = src.[Namespace],
  [SchemaName]      = src.[SchemaName],
  [TableName]       = src.[TableName],
  [OdsEnableType]   = src.[OdsEnableType],
  [DwhEnableType]   = src.[DwhEnableType]
WHEN NOT MATCHED BY TARGET THEN
INSERT ([CodeGenId], [Namespace], [SchemaName], [TableName], [OdsEnableType], [DwhEnableType])
  VALUES (
    src.[CodeGenId],
    src.[Namespace],
    src.[SchemaName],
    src.[TableName],
    src.[OdsEnableType],
    src.[DwhEnableType]
  )
WHEN NOT MATCHED BY SOURCE THEN DELETE;

--UPDATE [etl].[CodeGenDwhTable] SET [IsEnabled] = 1
--UPDATE [etl].[CodeGenDwhColumn] SET [IsEnabled] = 1
