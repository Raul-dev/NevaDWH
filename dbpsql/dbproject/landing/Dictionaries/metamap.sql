do
$$
BEGIN
RAISE NOTICE 'Fill metamap';
END;
$$;
INSERT INTO mq.metaadapter (metaadapter_id, name) 
SELECT * FROM (
SELECT 4, 'FirstBitJso'
UNION ALL SELECT 3, 'FirstBitXml'
UNION ALL SELECT 2, 'NevaDWHJso'
UNION ALL SELECT 1, 'NevaDWHXml'
UNION ALL SELECT 5, 'JsonXml'
) WHERE NOT EXISTS( SELECT 1 FROM mq.metaadapter WHERE metaadapter_id = 5);

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_metamap 
(
    metamap_id           SMALLINT       NOT NULL,
    msg_key             VARCHAR(256)    NOT NULL,
    table_name          VARCHAR(128)    NOT NULL,
    metaadapter_id      smallint        NULL,
    namespace           VARCHAR (256)   NULL,
    namespace_ver       VARCHAR (256)   NULL,
    etl_query           VARCHAR (256)   NULL,
    import_query        VARCHAR (256)   NULL,
    is_enabled            boolean NULL
);

INSERT INTO tmp_metamap (metamap_id, msg_key, table_name, metaadapter_id, namespace, namespace_ver, etl_query, import_query, is_enabled)
VALUES
(1, 'Unknow', 'mq.msgqueue', 5,CAST(NULL AS varchar(255)), CAST(NULL AS varchar(255)), NULL, NULL, true),
(2, 'Справочник.адаптер_СхемыДанных', 'mq.metadata_buffer', 4,CAST(NULL AS varchar(255)), CAST(NULL AS varchar(255)), 'mq.load_metadata', NULL, true),
(34, 'CatalogObject.Валюты', 'odins.DIM_Валюты_buffer', 1, 'http://nevadwh.ru/CatalogObject.Валюты', 'http://nevadwh.ru/CatalogObject.Валюты/version1', 'odins.load_DIM_Валюты',  'odins.load_DIM_Валюты_file', true),
(24, 'CatalogObject.Клиенты', 'odins.DIM_Клиенты_buffer', 1, 'http://nevadwh.ru/CatalogObject.Клиенты', 'http://nevadwh.ru/CatalogObject.Клиенты/version1', 'odins.load_DIM_Клиенты',  'odins.load_DIM_Клиенты_file', true),
(14, 'CatalogObject.Товары', 'odins.DIM_Товары_buffer', 1, 'http://nevadwh.ru/CatalogObject.Товары', 'http://nevadwh.ru/CatalogObject.Товары/version1', 'odins.load_DIM_Товары',  'odins.load_DIM_Товары_file', true),
(684, 'DocumentObject.Продажи', 'odins.FACT_Продажи_buffer', 1, 'http://nevadwh.ru/DocumentObject.Продажи', 'http://nevadwh.ru/DocumentObject.Продажи/version1', 'odins.load_FACT_Продажи',  'odins.load_FACT_Продажи_file', true),
(1314, 'InformationRegister.КурсыВалют', 'odins.DIM_КурсыВалют_buffer', 1, 'http://nevadwh.ru/InformationRegister.КурсыВалют', 'http://nevadwh.ru/InformationRegister.КурсыВалют/version1', 'odins.load_DIM_КурсыВалют',  'odins.load_DIM_КурсыВалют_file', true),
(3, 'CatalogObject.NevaDWH_Метаданные', 'mq.metadata_buffer', 1,CAST(NULL AS varchar(255)), CAST(NULL AS varchar(255)), 'mq.load_metadata', NULL, true)
;
UPDATE mq.metamap m
SET 
    msg_key = src.msg_key,
    table_name = src.table_name,
    metaadapter_id = src.metaadapter_id,
    namespace = src.namespace,
    namespace_ver = src.namespace_ver,
    etl_query = src.etl_query,
    import_query = src.import_query,
    is_enabled = src.is_enabled
FROM tmp_metamap src
WHERE m.msg_key = src.msg_key;

INSERT INTO mq.metamap(metamap_id, msg_key, table_name, metaadapter_id, namespace, namespace_ver, etl_query, import_query, is_enabled)
SELECT 
        src.metamap_id,
        src.msg_key,
        src.table_name,
        src.metaadapter_id,
        src.namespace,
        src.namespace_ver,
        src.etl_query,
        src.import_query,
        src.is_enabled
FROM tmp_metamap src
WHERE NOT src.msg_key IN (SELECT msg_key FROM mq.metamap)
;

DROP TABLE tmp_metamap;