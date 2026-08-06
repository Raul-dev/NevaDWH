DELETE [etl].[CodeGenDwhColumn]
DELETE [etl].[CodeGenDwhTable]
DECLARE @codegen TABLE
(
  [CodeGenId]       int NOT NULL,
  [Namespace]        nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
  [SchemaName]           nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
  [TableName]       nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
  [OdsEnableType]  smallint NULL,
  [DwhEnableType]  smallint NULL
)

INSERT @codegen ([CodeGenId], [Namespace], [SchemaName], [TableName], [OdsEnableType], [DwhEnableType])
SELECT TOP 0 [CodeGenId] = CAST(NULL AS int), [Namespace] = CAST(NULL AS nvarchar(256)), [SchemaName] = CAST(NULL AS nvarchar(128)), [TableName] = CAST(NULL AS nvarchar(256)), [OdsEnableType] = CAST(NULL AS smallint), [DwhEnableType] = CAST(NULL AS smallint) 
UNION ALL SELECT [CodeGenId] = 1, [Namespace] = N'https://nevadwh.ru/CatalogObject.Валюты', [SchemaName] = N'odins', [TableName] = N'DIM_Валюты', [OdsEnableType] = 3, [DwhEnableType] = 3 
UNION ALL SELECT [CodeGenId] = 2, [Namespace] = N'https://nevadwh.ru/CatalogObject.Клиенты', [SchemaName] = N'odins', [TableName] = N'DIM_Клиенты', [OdsEnableType] = 3, [DwhEnableType] = 3 
UNION ALL SELECT [CodeGenId] = 3, [Namespace] = N'https://nevadwh.ru/CatalogObject.Товары', [SchemaName] = N'odins', [TableName] = N'DIM_Товары', [OdsEnableType] = 3, [DwhEnableType] = 3 
UNION ALL SELECT [CodeGenId] = 4, [Namespace] = N'https://nevadwh.ru/DocumentObject.Продажи', [SchemaName] = N'odins', [TableName] = N'FACT_Продажи', [OdsEnableType] = 3, [DwhEnableType] = 3 

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

UNION ALL SELECT [CodeGenDwhTableId] = 1,  [CodeGenId] = 1,  [TableName] = 'DIM_Валюты',  [IsRoot] = 1,  [IsEnable] = 1,  [DwhTableName] = 'DIM_Валюты',  [IsVkeySession] = 0,  [IsVkeySourcename] = 0,  [IsHistorical] = 0
UNION ALL SELECT [CodeGenDwhTableId] = 2,  [CodeGenId] = 1,  [TableName] = 'DIM_Валюты.Представления',  [IsRoot] = 0,  [IsEnable] = 1,  [DwhTableName] = 'DIM_Валюты.Представления',  [IsVkeySession] = 0,  [IsVkeySourcename] = 0,  [IsHistorical] = 0
UNION ALL SELECT [CodeGenDwhTableId] = 3,  [CodeGenId] = 2,  [TableName] = 'DIM_Клиенты',  [IsRoot] = 1,  [IsEnable] = 1,  [DwhTableName] = 'DIM_Клиенты',  [IsVkeySession] = 0,  [IsVkeySourcename] = 0,  [IsHistorical] = 0
UNION ALL SELECT [CodeGenDwhTableId] = 4,  [CodeGenId] = 3,  [TableName] = 'DIM_Товары',  [IsRoot] = 1,  [IsEnable] = 1,  [DwhTableName] = 'DIM_Товары',  [IsVkeySession] = 0,  [IsVkeySourcename] = 0,  [IsHistorical] = 0
UNION ALL SELECT [CodeGenDwhTableId] = 5,  [CodeGenId] = 4,  [TableName] = 'FACT_Продажи',  [IsRoot] = 1,  [IsEnable] = 1,  [DwhTableName] = 'FACT_Продажи',  [IsVkeySession] = 0,  [IsVkeySourcename] = 0,  [IsHistorical] = 0
UNION ALL SELECT [CodeGenDwhTableId] = 6,  [CodeGenId] = 4,  [TableName] = 'FACT_Продажи.Товары',  [IsRoot] = 0,  [IsEnable] = 1,  [DwhTableName] = 'FACT_Продажи.Товары',  [IsVkeySession] = 0,  [IsVkeySourcename] = 0,  [IsHistorical] = 0


-- DIM_Валюты
INSERT [etl].[CodeGenDwhColumn]([CodeGenDwhColumnId],[CodeGenDwhTableId],[ColumnName],[DataType],[TextLength],[Precision],[Scale],[IsEnable],[IsVersionkey],[IsNulable],[NullValue] )
SELECT TOP 0 [CodeGenDwhColumnId] = CAST( NULL AS int),  [CodeGenDwhTableId] = CAST( NULL AS int),  [ColumnName] = CAST( NULL AS [varchar](128)),  [DataType] = CAST( NULL AS [varchar](128)),  [TextLength] = CAST( NULL AS [varchar](128)),  [Precision] = CAST( NULL AS [varchar](128)),  [Scale] = CAST( NULL AS [varchar](128)),  [IsEnable] = CAST( NULL AS [bit]),  [IsVersionkey] = CAST( NULL AS [bit]),  [IsNulable] = CAST( NULL AS [bit]),  [NullValue]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [CodeGenDwhColumnId] = 1,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'RefID',  [DataType] = 'uniqueidentifier',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'00000000-0000-0000-0000-000000000000'
UNION ALL SELECT [CodeGenDwhColumnId] = 2,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'DeletionMark',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 3,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'Code',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 4,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'Description',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 5,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'ЗагружаетсяИзИнтернета',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 6,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'НаименованиеПолное',  [DataType] = 'varchar',  [TextLength] = '50',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 7,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'Наценка',  [DataType] = 'decimal',  [TextLength] = NULL,  [Precision] = '10',  [Scale] = '2',  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 8,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'ОсновнаяВалюта',  [DataType] = 'varchar',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 9,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'ПараметрыПрописи',  [DataType] = 'varchar',  [TextLength] = '200',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 10,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'ФормулаРасчетаКурса',  [DataType] = 'varchar',  [TextLength] = '100',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 11,  [CodeGenDwhTableId] = 1,  [ColumnName] = 'СпособУстановкиКурса',  [DataType] = 'varchar',  [TextLength] = '500',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 12,  [CodeGenDwhTableId] = 2,  [ColumnName] = 'DIM_ВалютыRefID',  [DataType] = 'uniqueidentifier',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'00000000-0000-0000-0000-000000000000'
UNION ALL SELECT [CodeGenDwhColumnId] = 13,  [CodeGenDwhTableId] = 2,  [ColumnName] = 'КодЯзыка',  [DataType] = 'varchar',  [TextLength] = '10',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 14,  [CodeGenDwhTableId] = 2,  [ColumnName] = 'ПараметрыПрописи',  [DataType] = 'varchar',  [TextLength] = '200',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''

-- DIM_Клиенты
INSERT [etl].[CodeGenDwhColumn]([CodeGenDwhColumnId],[CodeGenDwhTableId],[ColumnName],[DataType],[TextLength],[Precision],[Scale],[IsEnable],[IsVersionkey],[IsNulable],[NullValue] )
SELECT TOP 0 [CodeGenDwhColumnId] = CAST( NULL AS int),  [CodeGenDwhTableId] = CAST( NULL AS int),  [ColumnName] = CAST( NULL AS [varchar](128)),  [DataType] = CAST( NULL AS [varchar](128)),  [TextLength] = CAST( NULL AS [varchar](128)),  [Precision] = CAST( NULL AS [varchar](128)),  [Scale] = CAST( NULL AS [varchar](128)),  [IsEnable] = CAST( NULL AS [bit]),  [IsVersionkey] = CAST( NULL AS [bit]),  [IsNulable] = CAST( NULL AS [bit]),  [NullValue]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [CodeGenDwhColumnId] = 15,  [CodeGenDwhTableId] = 3,  [ColumnName] = 'RefID',  [DataType] = 'uniqueidentifier',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'00000000-0000-0000-0000-000000000000'
UNION ALL SELECT [CodeGenDwhColumnId] = 16,  [CodeGenDwhTableId] = 3,  [ColumnName] = 'DeletionMark',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 17,  [CodeGenDwhTableId] = 3,  [ColumnName] = 'Code',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 18,  [CodeGenDwhTableId] = 3,  [ColumnName] = 'Description',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 19,  [CodeGenDwhTableId] = 3,  [ColumnName] = 'Контакт',  [DataType] = 'varchar',  [TextLength] = '500',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''

-- DIM_Товары
INSERT [etl].[CodeGenDwhColumn]([CodeGenDwhColumnId],[CodeGenDwhTableId],[ColumnName],[DataType],[TextLength],[Precision],[Scale],[IsEnable],[IsVersionkey],[IsNulable],[NullValue] )
SELECT TOP 0 [CodeGenDwhColumnId] = CAST( NULL AS int),  [CodeGenDwhTableId] = CAST( NULL AS int),  [ColumnName] = CAST( NULL AS [varchar](128)),  [DataType] = CAST( NULL AS [varchar](128)),  [TextLength] = CAST( NULL AS [varchar](128)),  [Precision] = CAST( NULL AS [varchar](128)),  [Scale] = CAST( NULL AS [varchar](128)),  [IsEnable] = CAST( NULL AS [bit]),  [IsVersionkey] = CAST( NULL AS [bit]),  [IsNulable] = CAST( NULL AS [bit]),  [NullValue]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [CodeGenDwhColumnId] = 20,  [CodeGenDwhTableId] = 4,  [ColumnName] = 'RefID',  [DataType] = 'uniqueidentifier',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'00000000-0000-0000-0000-000000000000'
UNION ALL SELECT [CodeGenDwhColumnId] = 21,  [CodeGenDwhTableId] = 4,  [ColumnName] = 'DeletionMark',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 22,  [CodeGenDwhTableId] = 4,  [ColumnName] = 'Code',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 23,  [CodeGenDwhTableId] = 4,  [ColumnName] = 'Description',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 24,  [CodeGenDwhTableId] = 4,  [ColumnName] = 'Описание',  [DataType] = 'varchar',  [TextLength] = '255',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''

-- FACT_Продажи
INSERT [etl].[CodeGenDwhColumn]([CodeGenDwhColumnId],[CodeGenDwhTableId],[ColumnName],[DataType],[TextLength],[Precision],[Scale],[IsEnable],[IsVersionkey],[IsNulable],[NullValue] )
SELECT TOP 0 [CodeGenDwhColumnId] = CAST( NULL AS int),  [CodeGenDwhTableId] = CAST( NULL AS int),  [ColumnName] = CAST( NULL AS [varchar](128)),  [DataType] = CAST( NULL AS [varchar](128)),  [TextLength] = CAST( NULL AS [varchar](128)),  [Precision] = CAST( NULL AS [varchar](128)),  [Scale] = CAST( NULL AS [varchar](128)),  [IsEnable] = CAST( NULL AS [bit]),  [IsVersionkey] = CAST( NULL AS [bit]),  [IsNulable] = CAST( NULL AS [bit]),  [NullValue]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [CodeGenDwhColumnId] = 25,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'RefID',  [DataType] = 'uniqueidentifier',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'00000000-0000-0000-0000-000000000000'
UNION ALL SELECT [CodeGenDwhColumnId] = 26,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'DeletionMark',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 27,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'Number',  [DataType] = 'int',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 28,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'Posted',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 29,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'Date',  [DataType] = 'datetime2',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'19000101'
UNION ALL SELECT [CodeGenDwhColumnId] = 30,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'DateID',  [DataType] = 'int',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 31,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'ДатаОтгрузки',  [DataType] = 'datetime2',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'19000101'
UNION ALL SELECT [CodeGenDwhColumnId] = 32,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'ДатаОтгрузкиID',  [DataType] = 'int',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 33,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'Клиент',  [DataType] = 'varchar',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 34,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'ТипДоставки',  [DataType] = 'varchar',  [TextLength] = '500',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 35,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'ПримерСоставногоТипа',  [DataType] = 'varchar',  [TextLength] = '36',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 36,  [CodeGenDwhTableId] = 5,  [ColumnName] = 'ПримерСоставногоТипа_ТипЗначения',  [DataType] = 'varchar',  [TextLength] = '128',  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 37,  [CodeGenDwhTableId] = 6,  [ColumnName] = 'FACT_ПродажиRefID',  [DataType] = 'uniqueidentifier',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'00000000-0000-0000-0000-000000000000'
UNION ALL SELECT [CodeGenDwhColumnId] = 38,  [CodeGenDwhTableId] = 6,  [ColumnName] = 'Доставка',  [DataType] = 'bit',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 39,  [CodeGenDwhTableId] = 6,  [ColumnName] = 'Товар',  [DataType] = 'varchar',  [TextLength] = NULL,  [Precision] = NULL,  [Scale] = NULL,  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N''
UNION ALL SELECT [CodeGenDwhColumnId] = 40,  [CodeGenDwhTableId] = 6,  [ColumnName] = 'Колличество',  [DataType] = 'decimal',  [TextLength] = NULL,  [Precision] = '12',  [Scale] = '0',  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'
UNION ALL SELECT [CodeGenDwhColumnId] = 41,  [CodeGenDwhTableId] = 6,  [ColumnName] = 'Цена',  [DataType] = 'decimal',  [TextLength] = NULL,  [Precision] = '16',  [Scale] = '4',  [IsEnable] = 1,  [IsVersionkey] = 0,  [IsNulable] = 0,  [NullValue]  = N'0'

