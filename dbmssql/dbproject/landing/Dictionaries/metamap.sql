IF NOT EXISTS(SELECT 1 FROM [dbo].[metaadapter] )
BEGIN
    INSERT INTO [dbo].[metaadapter] ([metaadapter_id],name) 
    SELECT 4, N'FirstBitJson'
    UNION ALL SELECT 3, N'FirstBitXml'
    UNION ALL SELECT 2, N'NevaDWHJson'
    UNION ALL SELECT 1, N'NevaDWHXml'
    UNION ALL SELECT 5, N'JsonXml'
END


DECLARE @metamap TABLE
(
    [metamap_id]            SMALLINT       NOT NULL,
    [msg_key]               NVARCHAR(256) NOT NULL,
    [table_name]            NVARCHAR(128) NOT NULL,
    [metaadapter_id]        tinyint    NULL,
    [namespace]             NVARCHAR (256)  NULL,
    [namespace_ver]         NVARCHAR (256)  NULL,
    [etl_query]             NVARCHAR (256)  NULL,
    [import_query]          NVARCHAR (256)  NULL,
    [is_enable]                BIT NULL
)



MERGE INTO [dbo].[metamap] trg
USING (
    SELECT m.* FROM @metamap m
        
    )
    src ON src.[metamap_id] = trg.[metamap_id]
WHEN MATCHED THEN UPDATE SET 
    [msg_key] = src.[msg_key],
    [table_name] = src.[table_name],
    [metaadapter_id] = src.[metaadapter_id],
    [namespace] = src.[namespace],
    [namespace_ver] = src.[namespace_ver],
    etl_query = src.etl_query,
    import_query = src.import_query,
    is_enable = src.is_enable
WHEN NOT MATCHED BY TARGET THEN 
INSERT (metamap_id, msg_key, table_name, metaadapter_id,[namespace], [namespace_ver], etl_query, import_query, is_enable)
    VALUES (
        src.metamap_id,
        src.[msg_key],
        src.[table_name],
        src.[metaadapter_id],
        src.[namespace],
        src.[namespace_ver],
        src.etl_query,
        src.import_query,
        src.is_enable
    )
WHEN NOT MATCHED BY SOURCE THEN DELETE;

GO
/*
INSERT INTO [dbo].[metamap]([metamap_id],[msg_key],[table_name],[metaadapter_id],[namespace]
 ,[namespace_ver],[etl_query],[import_query],[is_enable])
SELECT 6,'Документы.Продажи','FACT_Продажи',1,'http://neva.dwh/Документы.Продажи','http://neva.dwh/Документы.Продажи/version1','load_Продажи','load_Продажи_file',1
UNION ALL SELECT 5,'Справочники.NevaDWH_Метаданные','DIM_NevaDWH_Метаданные',1,'http://neva.dwh/Справочники.NevaDWH_Метаданные','http://neva.dwh/Справочники.NevaDWH_Метаданные/version1','load_NevaDWH_Метаданные','load_NevaDWH_Метаданные_file',1
UNION ALL SELECT 4,'Справочники.Клиенты','DIM_Клиенты',1,'http://neva.dwh/Справочники.Клиенты','http://neva.dwh/Справочники.Клиенты/version1','load_Клиенты','load_Клиенты_file',1
UNION ALL SELECT 3,'Справочники.Товары','DIM_Товары',1,'http://neva.dwh/Справочники.Товары','http://neva.dwh/Справочники.Товары/version1','load_Товары','load_Товары_file',1

*/
