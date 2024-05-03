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
    metamap_id           SMALLINT       NOT NULL,
    msg_key             VARCHAR(256)    NOT NULL,
    table_name          VARCHAR(128)    NOT NULL,
    metaadapter_id      smallint        NULL,
    namespace           VARCHAR (256)   NULL,
    namespace_ver       VARCHAR (256)   NULL,
    etl_query           VARCHAR (256)   NULL,
    import_query        VARCHAR (256)   NULL,
    is_enable            boolean NULL
);


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