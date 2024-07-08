DELETE [dbo].[codegen_dwh_column]
DELETE [dbo].[codegen_dwh_table]
DECLARE @codegen TABLE
(
    [codegen_id]       int NOT NULL,
    [namespace]        nvarchar(256) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [schema]           nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [table_name]       nvarchar(128) COLLATE Cyrillic_General_CI_AS NOT NULL,
    [ods_enable_type]  smallint NULL,
    [dwh_enable_type]  smallint NULL
)

INSERT @codegen ([codegen_id], [namespace], [schema], [table_name], [ods_enable_type], [dwh_enable_type])
SELECT TOP 0 [codegen_id] = CAST(NULL AS int), [namespace] = CAST(NULL AS nvarchar(256)), [schema] = CAST(NULL AS nvarchar(128)), [table_name] = CAST(NULL AS nvarchar(256)), [ods_enable_type] = CAST(NULL AS smallint), [dwh_enable_type] = CAST(NULL AS smallint) 
UNION ALL SELECT [codegen_id] = 1, [namespace] = N'https://nevadwh.ru/CatalogObject.Валюты', [schema] = N'odins', [table_name] = N'DIM_Валюты', [ods_enable_type] = 3, [dwh_enable_type] = 3 
UNION ALL SELECT [codegen_id] = 2, [namespace] = N'https://nevadwh.ru/CatalogObject.Клиенты', [schema] = N'odins', [table_name] = N'DIM_Клиенты', [ods_enable_type] = 3, [dwh_enable_type] = 3 
UNION ALL SELECT [codegen_id] = 3, [namespace] = N'https://nevadwh.ru/CatalogObject.Товары', [schema] = N'odins', [table_name] = N'DIM_Товары', [ods_enable_type] = 3, [dwh_enable_type] = 3 
UNION ALL SELECT [codegen_id] = 4, [namespace] = N'https://nevadwh.ru/DocumentObject.Продажи', [schema] = N'odins', [table_name] = N'FACT_Продажи', [ods_enable_type] = 3, [dwh_enable_type] = 3 

IF EXISTS ( 
    SELECT 1 FROM codegen d 
    LEFT OUTER JOIN @codegen s ON s.[codegen_id] = d.[codegen_id]
    WHERE s.[codegen_id] IS NULL) THROW 60000, N'The table [dbo].[codegen] was change.', 1;

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

INSERT [dbo].[codegen_dwh_table] ([codegen_dwh_table_id], [codegen_id], [table_name], [is_root], [is_enable], [dwh_table_name], [is_vkey_session], [is_vkey_sourcename], [is_historical])
SELECT TOP 0 [codegen_dwh_table_ID] = CAST( NULL AS int), [codegen_id] = CAST( NULL AS int), [table_name] = CAST( NULL AS varchar(128)), [is_root] = CAST( NULL AS BIT), [is_enable] = CAST( NULL AS BIT), [dwh_table_name] = CAST( NULL AS varchar(128)), [is_vkey_session] = CAST( NULL AS BIT), [is_vkey_sourcename] = CAST( NULL AS BIT), [is_historical] = CAST( NULL AS BIT)

UNION ALL SELECT [codegen_dwh_table_ID] = 1, [codegen_id] = 1, [table_name] = 'DIM_Валюты', [is_root] = 1, [is_enable] = 1, [dwh_table_name] = 'DIM_Валюты', [is_vkey_session] = 0, [is_vkey_sourcename] = 0, [is_historical] = 0
UNION ALL SELECT [codegen_dwh_table_ID] = 2, [codegen_id] = 1, [table_name] = 'DIM_Валюты.Представления', [is_root] = 0, [is_enable] = 1, [dwh_table_name] = 'DIM_Валюты.Представления', [is_vkey_session] = 0, [is_vkey_sourcename] = 0, [is_historical] = 0
UNION ALL SELECT [codegen_dwh_table_ID] = 3, [codegen_id] = 2, [table_name] = 'DIM_Клиенты', [is_root] = 1, [is_enable] = 1, [dwh_table_name] = 'DIM_Клиенты', [is_vkey_session] = 0, [is_vkey_sourcename] = 0, [is_historical] = 1
UNION ALL SELECT [codegen_dwh_table_ID] = 4, [codegen_id] = 3, [table_name] = 'DIM_Товары', [is_root] = 1, [is_enable] = 1, [dwh_table_name] = 'DIM_Товары', [is_vkey_session] = 0, [is_vkey_sourcename] = 0, [is_historical] = 1
UNION ALL SELECT [codegen_dwh_table_ID] = 5, [codegen_id] = 4, [table_name] = 'FACT_Продажи', [is_root] = 1, [is_enable] = 1, [dwh_table_name] = 'FACT_Продажи', [is_vkey_session] = 0, [is_vkey_sourcename] = 0, [is_historical] = 0
UNION ALL SELECT [codegen_dwh_table_ID] = 6, [codegen_id] = 4, [table_name] = 'FACT_Продажи.Товары', [is_root] = 0, [is_enable] = 1, [dwh_table_name] = 'FACT_Продажи.Товары', [is_vkey_session] = 0, [is_vkey_sourcename] = 0, [is_historical] = 0


-- DIM_Валюты
INSERT [dbo].[codegen_dwh_column]([codegen_dwh_column_id],[codegen_dwh_table_id],[column_name],[data_type],[text_length],[precision],[scale],[is_enable],[is_versionkey],[is_nulable],[null_value] )
SELECT TOP 0 [codegen_dwh_column_id] = CAST( NULL AS int), [codegen_dwh_table_id] = CAST( NULL AS int), [column_name] = CAST( NULL AS [varchar](128)), [data_type] = CAST( NULL AS [varchar](128)), [text_length] = CAST( NULL AS [varchar](128)), [precision] = CAST( NULL AS [varchar](128)), [scale] = CAST( NULL AS [varchar](128)), [is_enable] = CAST( NULL AS [bit]), [is_versionkey] = CAST( NULL AS [bit]), [is_nulable] = CAST( NULL AS [bit]), [null_value]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [codegen_dwh_column_id] = 1, [codegen_dwh_table_id] = 1, [column_name] = 'RefID', [data_type] = 'uniqueidentifier', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 2, [codegen_dwh_table_id] = 1, [column_name] = 'DeletionMark', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 3, [codegen_dwh_table_id] = 1, [column_name] = 'Code', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 4, [codegen_dwh_table_id] = 1, [column_name] = 'Description', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 5, [codegen_dwh_table_id] = 1, [column_name] = 'ЗагружаетсяИзИнтернета', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 6, [codegen_dwh_table_id] = 1, [column_name] = 'НаименованиеПолное', [data_type] = 'varchar', [text_length] = '50', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 7, [codegen_dwh_table_id] = 1, [column_name] = 'Наценка', [data_type] = 'decimal', [text_length] = NULL, [precision] = '10', [scale] = '2', [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 8, [codegen_dwh_table_id] = 1, [column_name] = 'ОсновнаяВалюта', [data_type] = 'varchar', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 9, [codegen_dwh_table_id] = 1, [column_name] = 'ПараметрыПрописи', [data_type] = 'varchar', [text_length] = '200', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 10, [codegen_dwh_table_id] = 1, [column_name] = 'ФормулаРасчетаКурса', [data_type] = 'varchar', [text_length] = '100', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 11, [codegen_dwh_table_id] = 1, [column_name] = 'СпособУстановкиКурса', [data_type] = 'varchar', [text_length] = '500', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 12, [codegen_dwh_table_ID] = 2, [column_name] = 'DIM_ВалютыRefID', [data_type] = 'uniqueidentifier', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 13, [codegen_dwh_table_ID] = 2, [column_name] = 'КодЯзыка', [data_type] = 'varchar', [text_length] = '10', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 14, [codegen_dwh_table_ID] = 2, [column_name] = 'ПараметрыПрописи', [data_type] = 'varchar', [text_length] = '200', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL

-- DIM_Клиенты
INSERT [dbo].[codegen_dwh_column]([codegen_dwh_column_id],[codegen_dwh_table_id],[column_name],[data_type],[text_length],[precision],[scale],[is_enable],[is_versionkey],[is_nulable],[null_value] )
SELECT TOP 0 [codegen_dwh_column_id] = CAST( NULL AS int), [codegen_dwh_table_id] = CAST( NULL AS int), [column_name] = CAST( NULL AS [varchar](128)), [data_type] = CAST( NULL AS [varchar](128)), [text_length] = CAST( NULL AS [varchar](128)), [precision] = CAST( NULL AS [varchar](128)), [scale] = CAST( NULL AS [varchar](128)), [is_enable] = CAST( NULL AS [bit]), [is_versionkey] = CAST( NULL AS [bit]), [is_nulable] = CAST( NULL AS [bit]), [null_value]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [codegen_dwh_column_id] = 15, [codegen_dwh_table_id] = 3, [column_name] = 'RefID', [data_type] = 'uniqueidentifier', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 16, [codegen_dwh_table_id] = 3, [column_name] = 'DeletionMark', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 17, [codegen_dwh_table_id] = 3, [column_name] = 'Code', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 18, [codegen_dwh_table_id] = 3, [column_name] = 'Description', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 19, [codegen_dwh_table_id] = 3, [column_name] = 'Контакт', [data_type] = 'varchar', [text_length] = '500', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL

-- DIM_Товары
INSERT [dbo].[codegen_dwh_column]([codegen_dwh_column_id],[codegen_dwh_table_id],[column_name],[data_type],[text_length],[precision],[scale],[is_enable],[is_versionkey],[is_nulable],[null_value] )
SELECT TOP 0 [codegen_dwh_column_id] = CAST( NULL AS int), [codegen_dwh_table_id] = CAST( NULL AS int), [column_name] = CAST( NULL AS [varchar](128)), [data_type] = CAST( NULL AS [varchar](128)), [text_length] = CAST( NULL AS [varchar](128)), [precision] = CAST( NULL AS [varchar](128)), [scale] = CAST( NULL AS [varchar](128)), [is_enable] = CAST( NULL AS [bit]), [is_versionkey] = CAST( NULL AS [bit]), [is_nulable] = CAST( NULL AS [bit]), [null_value]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [codegen_dwh_column_id] = 20, [codegen_dwh_table_id] = 4, [column_name] = 'RefID', [data_type] = 'uniqueidentifier', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 21, [codegen_dwh_table_id] = 4, [column_name] = 'DeletionMark', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 22, [codegen_dwh_table_id] = 4, [column_name] = 'Code', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 23, [codegen_dwh_table_id] = 4, [column_name] = 'Description', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 24, [codegen_dwh_table_id] = 4, [column_name] = 'Описание', [data_type] = 'varchar', [text_length] = '255', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL

-- FACT_Продажи
INSERT [dbo].[codegen_dwh_column]([codegen_dwh_column_id],[codegen_dwh_table_id],[column_name],[data_type],[text_length],[precision],[scale],[is_enable],[is_versionkey],[is_nulable],[null_value] )
SELECT TOP 0 [codegen_dwh_column_id] = CAST( NULL AS int), [codegen_dwh_table_id] = CAST( NULL AS int), [column_name] = CAST( NULL AS [varchar](128)), [data_type] = CAST( NULL AS [varchar](128)), [text_length] = CAST( NULL AS [varchar](128)), [precision] = CAST( NULL AS [varchar](128)), [scale] = CAST( NULL AS [varchar](128)), [is_enable] = CAST( NULL AS [bit]), [is_versionkey] = CAST( NULL AS [bit]), [is_nulable] = CAST( NULL AS [bit]), [null_value]  = CAST( NULL AS [varchar](128))
UNION ALL SELECT [codegen_dwh_column_id] = 25, [codegen_dwh_table_id] = 5, [column_name] = 'RefID', [data_type] = 'uniqueidentifier', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 26, [codegen_dwh_table_id] = 5, [column_name] = 'DeletionMark', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 27, [codegen_dwh_table_id] = 5, [column_name] = 'Number', [data_type] = 'int', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 28, [codegen_dwh_table_id] = 5, [column_name] = 'Posted', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 29, [codegen_dwh_table_id] = 5, [column_name] = 'Date', [data_type] = 'datetime2', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 30, [codegen_dwh_table_id] = 5, [column_name] = 'ДатаОтгрузки', [data_type] = 'datetime2', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 31, [codegen_dwh_table_id] = 5, [column_name] = 'Клиент', [data_type] = 'varchar', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 32, [codegen_dwh_table_id] = 5, [column_name] = 'ТипДоставки', [data_type] = 'varchar', [text_length] = '500', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 33, [codegen_dwh_table_id] = 5, [column_name] = 'ПримерСоставногоТипа', [data_type] = 'varchar', [text_length] = '36', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 34, [codegen_dwh_table_id] = 5, [column_name] = 'ПримерСоставногоТипа_ТипЗначения', [data_type] = 'varchar', [text_length] = '128', [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 35, [codegen_dwh_table_ID] = 6, [column_name] = 'FACT_ПродажиRefID', [data_type] = 'uniqueidentifier', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 36, [codegen_dwh_table_ID] = 6, [column_name] = 'Доставка', [data_type] = 'bit', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 37, [codegen_dwh_table_ID] = 6, [column_name] = 'Товар', [data_type] = 'varchar', [text_length] = NULL, [precision] = NULL, [scale] = NULL, [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 38, [codegen_dwh_table_ID] = 6, [column_name] = 'Колличество', [data_type] = 'decimal', [text_length] = NULL, [precision] = '12', [scale] = '0', [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL
UNION ALL SELECT [codegen_dwh_column_id] = 39, [codegen_dwh_table_ID] = 6, [column_name] = 'Цена', [data_type] = 'decimal', [text_length] = NULL, [precision] = '16', [scale] = '4', [is_enable] = 1, [is_versionkey] = 0, [is_nulable] = 1, [null_value]  = NULL

