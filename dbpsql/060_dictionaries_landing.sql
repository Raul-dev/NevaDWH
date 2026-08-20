\c newadwh_landing;

do
$$
BEGIN
RAISE NOTICE 'Fill codege';
END;
$$;
DELETE FROM etl.codegen_dwh_column;
DELETE FROM etl.codegen_dwh_table;
DROP TABLE IF EXISTS tmp_codegen ;
CREATE TEMPORARY TABLE IF NOT EXISTS tmp_codegen 
(
    codegen_id int NOT NULL,
    namespace character varying(256) NOT NULL,
    schema character varying(128) NOT NULL,
    table_name character varying(128) NOT NULL,
    ods_enable_type smallint NULL,
    dwh_enable_type smallint NULL
);

INSERT INTO tmp_codegen (codegen_id,namespace, schema, table_name, ods_enable_type, dwh_enable_type)
SELECT  34 AS codegen_id, 'http://nevadwh.ru/CatalogObject.Валюты' AS namespace, 'odins' AS schema, 'DIM_Валюты' AS table_name, 3 AS ods_enable_type, 3 AS dwh_enable_type
UNION ALL SELECT 24, 'http://nevadwh.ru/CatalogObject.Клиенты', 'odins', 'DIM_Клиенты', 3, 3
UNION ALL SELECT 14, 'http://nevadwh.ru/CatalogObject.Товары', 'odins', 'DIM_Товары', 3, 3
UNION ALL SELECT 684, 'http://nevadwh.ru/DocumentObject.Продажи', 'odins', 'FACT_Продажи',  3, 3
UNION ALL SELECT 1314, 'http://nevadwh.ru/InformationRegister.КурсыВалют', 'odins', 'DIM_КурсыВалют', 0, 0

;
UPDATE etl.codegen c
SET
    codegen_id = src.codegen_id,
    namespace = src.namespace,
    schema = src.schema,
    table_name = src.table_name,
    ods_enable_type = src.ods_enable_type,
    dwh_enable_type = src.dwh_enable_type
FROM tmp_codegen src
WHERE c.codegen_id = src.codegen_id;

INSERT INTO etl.codegen(codegen_id,namespace, schema, table_name, ods_enable_type, dwh_enable_type)
SELECT  src.codegen_id,
        src.namespace,
        src.schema,
        src.table_name,
        src.ods_enable_type,
        src.dwh_enable_type
FROM tmp_codegen src
WHERE NOT src.codegen_id in (SELECT src.codegen_id FROM etl.codegen s );


INSERT INTO etl.codegen_dwh_table (codegen_dwh_table_id, codegen_id, table_name, is_root, is_enabled, dwh_table_name, is_vkey_session, is_vkey_sourcename, is_historical)
(SELECT     cast( null as int) as codegen_dwh_table_id ,       cast( null as int) as codegen_id,       cast( null as varchar(128)) as table_name,       cast( null as boolean) as is_root,       cast( null as boolean) as is_enabled,       cast( null as varchar(128)) as dwh_table_name,    cast( null as boolean) as is_vkey_session,       cast( null as boolean) as is_vkey_sourcename,    cast( null as boolean) as is_historical
FROM (VALUES ('Z')) t1 (col1) LIMIT 0)
  ;
INSERT INTO etl.codegen_dwh_column(codegen_dwh_column_id, codegen_dwh_table_id, column_name, data_type, text_length, precision, scale, is_enabled, is_versionkey, is_nulable, null_value)
(SELECT cast( null as int) as codegen_dwh_column_id,   cast( null as int) as codegen_dwh_table_id,   cast( null as varchar(128)) as column_name,   cast( null as varchar(128)) as data_type,   cast( null as integer) as text_length ,   cast( null as integer) as precision ,   cast( null as integer) as scale ,   cast( null as boolean) as is_enabled,cast( null as boolean) as is_versionkey,cast( null as boolean) as is_nulable,cast( null as varchar(128)) as null_value 
   FROM (VALUES ('Z')) t1 (col1) LIMIT 0)
;
DROP TABLE tmp_codegen;
do
$$
BEGIN
RAISE NOTICE 'Fill codegen_enable_type ';
END;
$$;


CREATE TEMPORARY TABLE IF NOT EXISTS tmp_codegen_enable_type 
(
    codegen_enable_type_id smallint,
    "description" VARCHAR(100)
);


INSERT INTO tmp_codegen_enable_type (codegen_enable_type_id, "description") VALUES
(0, 'Исключить из проекта ODS'),
(1, 'Генерировать код ODS если файлы отсутствуют'),
(2, 'Генерировать только ODS таблицы всегда , процедуры только если отсутствуют'),
(3, 'Генерировать код ODS');



UPDATE etl.codegen_enable_type as c
SET description = t.description
FROM tmp_codegen_enable_type as t
WHERE c.codegen_enable_type_id = t.codegen_enable_type_id;

INSERT INTO etl.codegen_enable_type (codegen_enable_type_id, description)
SELECT * FROM tmp_codegen_enable_type t
WHERE  NOT t.codegen_enable_type_id in (SELECT codegen_enable_type_id FROM etl.codegen_enable_type c);

DROP TABLE tmp_codegen_enable_type;


do
$$
BEGIN
RAISE NOTICE 'Fill dwh_session_state ';
END;
$$;

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_dwh_session_state 
(
    dwh_session_state_id smallint,
    name VARCHAR(100)
);

INSERT INTO tmp_dwh_session_state (dwh_session_state_id, name)VALUES
(1, N'Начало обработки DWH'),
(2, N'Завершение обработки DWH'),
(6, N'Завершение обработки DWH'),
(7, N'Ошибка обработки DWH');


UPDATE etl.dwh_session_state as c
SET name = t.name
FROM tmp_dwh_session_state as t
WHERE c.dwh_session_state_id = t.dwh_session_state_id;

INSERT INTO etl.dwh_session_state (dwh_session_state_id, name)
SELECT * FROM tmp_dwh_session_state t
WHERE  NOT t.dwh_session_state_id in (SELECT dwh_session_state_id FROM etl.dwh_session_state c);

DROP TABLE tmp_dwh_session_state;
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

do
$$
BEGIN
RAISE NOTICE 'Fill data_source';
END;
$$;

insert into mq.data_source (data_source_id,name)
SELECT 1, N'ods1c'
WHERE NOT EXISTS(SELECT 1 FROM mq.data_source WHERe data_source_id =1 );

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_session_state 
(
    session_state_id smallint,
    name VARCHAR(100)
);

INSERT INTO tmp_session_state (session_state_id, name)VALUES
(1, N'Начало обработки очереди RabbitMQ'),
(2, N'Завершение обработки очереди RabbitMQ'),
(3, N'Ошибка обработки очереди RabbitMQ'),
(4, N'Ошибка обработки буфера');

UPDATE mq.session_state as c
SET name = t.name
FROM tmp_session_state as t
WHERE c.session_state_id = t.session_state_id;

INSERT INTO mq.session_state (session_state_id, name)
SELECT * FROM tmp_session_state t
WHERE  NOT t.session_state_id in (SELECT session_state_id FROM mq.session_state c);

DROP TABLE tmp_session_state;
