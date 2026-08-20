IF NOT EXISTS(SELECT 1 FROM [mq].[MetaAdapter])
BEGIN
  INSERT INTO [mq].[MetaAdapter] ([MetaAdapterId], [Name])
  SELECT 4, N'FirstBitJson'
  UNION ALL SELECT 3, N'FirstBitXml'
  UNION ALL SELECT 2, N'NevaDWHJson'
  UNION ALL SELECT 1, N'NevaDWHXml'
  UNION ALL SELECT 5, N'JsonXml'
END

DECLARE @metamap TABLE
(
  [MetaMapId]        SMALLINT       NOT NULL,
  [MessageKey]       NVARCHAR(256)  NOT NULL,
  [TableName]        NVARCHAR(128)  NOT NULL,
  [MetaAdapterId]    TINYINT        NULL,
  [Namespace]        NVARCHAR(256)  NULL,
  [NamespaceVersion] NVARCHAR(256)  NULL,
  [EtlProcedure]     NVARCHAR(256)  NULL,
  [ImportQuery]      NVARCHAR(256)  NULL,
  [IsEnabled]        BIT            NULL
)

INSERT @metamap ([MetaMapId], [MessageKey], [TableName], [MetaAdapterId], [Namespace], [NamespaceVersion], [EtlProcedure], [ImportQuery], [IsEnabled])
VALUES
(9001, N'Unknown', N'mq.MessageQueue', 5, CAST(NULL AS varchar(255)), CAST(NULL AS varchar(255)), NULL, NULL, 1),
(9002, N'Справочник.адаптер_СхемыДанных', N'[mq].[MetaDataBuffer]', 4, CAST(N'Справочник.адаптер_СхемыДанных' AS varchar(255)), CAST(N'Справочник.адаптер_СхемыДанных' AS varchar(255)), N'[mq].[load_MetaData]', NULL, 1),
(9003, N'CatalogObject.NevaDWH_Метаданные', N'[mq].[MetaDataBuffer]', 1, CAST(N'CatalogObject.NevaDWH_Метаданные' AS varchar(255)), CAST(N'CatalogObject.NevaDWH_Метаданные' AS varchar(255)), N'[mq].[load_MetaData]', NULL, 1)

IF EXISTS (
  SELECT 1 FROM [mq].[MetaMap] d
  LEFT OUTER JOIN @metamap s ON s.[MetaMapId] = d.[MetaMapId]
  WHERE s.[MetaMapId] IS NULL) THROW 60000, N'The table [mq].[MetaMap] was change.', 1;

MERGE INTO [mq].[MetaMap] trg
USING @metamap src ON src.[MetaMapId] = trg.[MetaMapId]
WHEN MATCHED THEN UPDATE SET
  [MessageKey]       = src.[MessageKey],
  [TableName]        = src.[TableName],
  [MetaAdapterId]    = src.[MetaAdapterId],
  [Namespace]        = src.[Namespace],
  [NamespaceVersion] = src.[NamespaceVersion],
  [EtlProcedure]     = src.[EtlProcedure],
  [ImportQuery]      = src.[ImportQuery],
  [IsEnabled]        = src.[IsEnabled]
WHEN NOT MATCHED BY TARGET THEN
INSERT ([MetaMapId], [MessageKey], [TableName], [MetaAdapterId], [Namespace], [NamespaceVersion], [EtlProcedure], [ImportQuery], [IsEnabled])
  VALUES (
    src.[MetaMapId],
    src.[MessageKey],
    src.[TableName],
    src.[MetaAdapterId],
    src.[Namespace],
    src.[NamespaceVersion],
    src.[EtlProcedure],
    src.[ImportQuery],
    src.[IsEnabled]
  )
WHEN NOT MATCHED BY SOURCE THEN DELETE;

GO
