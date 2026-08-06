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

INSERT @codegen ([CodeGenId], [Namespace], [SchemaName], [TableName], [OdsEnableType], [DwhEnableType])
SELECT TOP 0 [CodeGenId] = CAST(NULL AS int), [Namespace] = CAST(NULL AS nvarchar(256)), [SchemaName] = CAST(NULL AS nvarchar(128)), [TableName] = CAST(NULL AS nvarchar(256)), [OdsEnableType] = CAST(NULL AS smallint), [DwhEnableType] = CAST(NULL AS smallint) 

IF EXISTS ( 
  SELECT 1 FROM [etl].[CodeGen] d 
  LEFT OUTER JOIN @codegen s ON s.[CodeGenId] = d.[CodeGenId]
  WHERE s.[CodeGenId] IS NULL) THROW 60000, N'The table [etl].[CodeGen] was change.', 1;

MERGE INTO [etl].[CodeGen] trg
USING 
@codegen src ON src.[CodeGenId] = trg.[CodeGenId]
WHEN MATCHED THEN UPDATE SET 
  [CodeGenId] = src.[CodeGenId],
  [Namespace] = src.[Namespace],
  [SchemaName] = src.[SchemaName],
  [TableName] = src.[TableName],
  [OdsEnableType] = src.[OdsEnableType],
  [DwhEnableType] = src.[DwhEnableType]
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

--UPDATE [etl].[CodeGenDwhTable] SET [IsEnable] = 1
--UPDATE [etl].[CodeGenDwhColumn] SET [IsEnable] = 1

INSERT [etl].[CodeGenDwhTable] ([CodeGenDwhTableId], [CodeGenId], [TableName], [IsRoot], [IsEnable], [DwhTableName], [IsVkeySession], [IsVkeySourcename], [IsHistorical])
SELECT TOP 0 [CodeGenDwhTableId] = CAST( NULL AS int),  [CodeGenId] = CAST( NULL AS int),  [TableName] = CAST( NULL AS varchar(128)),  [IsRoot] = CAST( NULL AS BIT),  [IsEnable] = CAST( NULL AS BIT),  [DwhTableName] = CAST( NULL AS varchar(128)),  [IsVkeySession] = CAST( NULL AS BIT),  [IsVkeySourcename] = CAST( NULL AS BIT),  [IsHistorical] = CAST( NULL AS BIT)



