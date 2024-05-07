do
$$
BEGIN
RAISE NOTICE 'Fill metamap';
END;
$$;
INSERT INTO metaadapter (metaadapter_id, name) 
SELECT * FROM (
SELECT 4, 'FirstBitJso'
UNION ALL SELECT 3, 'FirstBitXml'
UNION ALL SELECT 2, 'NevaDWHJso'
UNION ALL SELECT 1, 'NevaDWHXml'
UNION ALL SELECT 5, 'JsonXml'
) WHERE NOT EXISTS( SELECT 1 FROM metaadapter WHERE metaadapter_id = 5);
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_metamap 
(
    metamap_id          smallint        NOT NULL,
    msg_key             varchar(256)    NOT NULL,
    table_name          varchar(128)    NOT NULL,
    metaadapter_id      smallint        NULL,
    namespace           varchar (256)   NULL,
    namespace_ver       varchar (256)   NULL,
    etl_query           varchar (256)   NULL,
    import_query        varchar (256)   NULL,
    is_enable           boolean         NULL
);

INSERT INTO tmp_metamap (metamap_id, msg_key, table_name, metaadapter_id, namespace, namespace_ver, etl_query, import_query, is_enable)
VALUES
(1, 'Unknown', 'msgqueue', 5,CAST('https://nevadwh.ru/CatalogObject.Unknown' AS varchar(255)), CAST('https://nevadwh.ru/CatalogObject.Unknown/version1' AS varchar(255)), NULL, NULL, true),
(6, N'CatalogObject.Валюты', N'odins."DIM_Валюты_buffer"', 1, N'https://nevadwh.ru/CatalogObject.Валюты', N'https://nevadwh.ru/CatalogObject.Валюты/version1', 'odins."load_DIM_Валюты"', N'odins.[load_DIM_Валюты_file]', false),
(5, N'CatalogObject.Клиенты', N'odins."DIM_Клиенты_buffer"', 1, N'https://nevadwh.ru/CatalogObject.Клиенты', N'https://nevadwh.ru/CatalogObject.Клиенты/version1', 'odins."load_DIM_Клиенты"', N'odins.[load_DIM_Клиенты_file]', true),
(4, N'CatalogObject.Товары', N'odins."DIM_Товары_buffer"', 1, N'https://nevadwh.ru/CatalogObject.Товары', N'https://nevadwh.ru/CatalogObject.Товары/version1', 'odins."load_DIM_Товары"', N'odins.[load_DIM_Товары_file]', true),
(70, N'DocumentObject.Продажи', N'odins."FACT_Продажи_buffer"', 1, N'https://nevadwh.ru/DocumentObject.Продажи', N'https://nevadwh.ru/DocumentObject.Продажи/version1', 'odins."load_FACT_Продажи"', N'odins.[load_FACT_Продажи_file]', false),
(2, N'Справочник.адаптер_СхемыДанных', 'metadata_buffer', 4, CAST('https://nevadwh.ru/Справочник.адаптер_СхемыДанных' AS varchar(255)), CAST('https://nevadwh.ru/Справочник.адаптер_СхемыДанных/version1' AS varchar(255)), 'load_metadata', NULL, true),
(3, N'CatalogObject.NevaDWH_Метаданные', 'metadata_buffer', 1, CAST('https://nevadwh.ru/CatalogObject.ВариантыОтветовАнкет' AS varchar(255)), CAST('https://nevadwh.ru/CatalogObject.ВариантыОтветовАнкет/version1' AS varchar(255)), 'load_metadata', NULL, true)
;
UPDATE metamap m
SET 
    msg_key = src.msg_key,
    table_name = src.table_name,
    metaadapter_id = src.metaadapter_id,
    namespace = src.namespace,
    namespace_ver = src.namespace_ver,
    etl_query = src.etl_query,
    import_query = src.import_query,
    is_enable = src.is_enable
FROM tmp_metamap src
WHERE m.msg_key = src.msg_key;

INSERT INTO metamap(metamap_id, msg_key, table_name, metaadapter_id, namespace, namespace_ver, etl_query, import_query, is_enable)
SELECT 
        src.metamap_id,
        src.msg_key,
        src.table_name,
        src.metaadapter_id,
        src.namespace,
        src.namespace_ver,
        src.etl_query,
        src.import_query,
        src.is_enable
FROM tmp_metamap src
WHERE NOT src.msg_key IN (SELECT msg_key FROM metamap)
;

DROP TABLE tmp_metamap;