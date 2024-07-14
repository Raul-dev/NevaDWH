\c nevadwh_ods;

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



UPDATE codegen_enable_type as c
SET description = t.description
FROM tmp_codegen_enable_type as t
WHERE c.codegen_enable_type_id = t.codegen_enable_type_id;

INSERT INTO codegen_enable_type (codegen_enable_type_id, description)
SELECT * FROM tmp_codegen_enable_type t
WHERE  NOT t.codegen_enable_type_id in (SELECT codegen_enable_type_id FROM codegen_enable_type c);

DROP TABLE tmp_codegen_enable_type;

do
$$
BEGIN
RAISE NOTICE 'Fill codegen';
END;
$$;
DELETE FROM codegen_dwh_column;
DELETE FROM codegen_dwh_table;

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_codegen 
(
    codegen_id int NOT NULL,
    namespace character varying(256) NOT NULL,
    schema character varying(128) NOT NULL,
    table_name character varying(128) NOT NULL,
    ods_enable_type smallint NULL,
    dwh_enable_type smallint NULL
);

INSERT INTO tmp_codegen (codegen_id, namespace, schema, table_name, ods_enable_type, dwh_enable_type)
SELECT 0::integer, ''::character varying(256), ''::character varying(128), ''::character varying(128), 0::smallint, 0::smallint
FROM generate_series('2018-01-31', '2018-01-31', interval '1 month') as gs
WHERE gs::date ='2018-02-28'
UNION SELECT 1, N'https://nevadwh.ru/CatalogObject.Валюты', N'odins', N'DIM_Валюты', 3, 3 
UNION SELECT 2, N'https://nevadwh.ru/CatalogObject.Клиенты', N'odins', N'DIM_Клиенты', 3, 3 
UNION SELECT 3, N'https://nevadwh.ru/CatalogObject.Товары', N'odins', N'DIM_Товары', 3, 3 
UNION SELECT 4, N'https://nevadwh.ru/DocumentObject.Продажи', N'odins', N'FACT_Продажи', 3, 3 
;
UPDATE codegen c
SET
    codegen_id = src.codegen_id,
    namespace = src.namespace,
    schema = src.schema,
    table_name = src.table_name,
    ods_enable_type = src.ods_enable_type,
    dwh_enable_type = src.dwh_enable_type
FROM tmp_codegen src
WHERE c.codegen_id = src.codegen_id;

INSERT INTO codegen(codegen_id,namespace, schema, table_name, ods_enable_type, dwh_enable_type)
SELECT  src.codegen_id,
        src.namespace,
        src.schema,
        src.table_name,
        src.ods_enable_type,
        src.dwh_enable_type
FROM tmp_codegen src
WHERE NOT src.codegen_id in (SELECT src.codegen_id FROM codegen s );


INSERT INTO codegen_dwh_table (codegen_dwh_table_id, codegen_id, table_name, is_root, is_enable, dwh_table_name, is_vkey_session, is_vkey_sourcename, is_historical)
(SELECT     cast( null as int) as codegen_dwh_table_id ,       cast( null as int) as codegen_id,       cast( null as varchar(128)) as table_name,       cast( null as boolean) as is_root,       cast( null as boolean) as is_enable,       cast( null as varchar(128)) as dwh_table_name,    cast( null as boolean) as is_vkey_session,       cast( null as boolean) as is_vkey_sourcename,    cast( null as boolean) as is_historical
FROM (VALUES ('Z')) t1 (col1) LIMIT 0)
UNION SELECT 1, 1, 'DIM_Валюты', true, true ,  'DIM_Валюты', false, false, false
UNION SELECT 2, 1, 'DIM_Валюты.Представления', false, true, 'DIM_Валюты.Представления', false, false, false
UNION SELECT 3, 2, 'DIM_Клиенты', true, true ,  'DIM_Клиенты', false, false, true
UNION SELECT 4, 3, 'DIM_Товары', true, true ,  'DIM_Товары', false, false, true
UNION SELECT 5, 4, 'FACT_Продажи', true, true ,  'FACT_Продажи', false, false, false
UNION SELECT 6, 1, 'FACT_Продажи.Товары', false, true, 'FACT_Продажи.Товары', false, false, false
;
INSERT INTO codegen_dwh_column(codegen_dwh_column_id, codegen_dwh_table_id, column_name, data_type, text_length, precision, scale, is_enable, is_versionkey, is_nulable, null_value)
(SELECT cast( null as int) as codegen_dwh_column_id,   cast( null as int) as codegen_dwh_table_id,   cast( null as varchar(128)) as column_name,   cast( null as varchar(128)) as data_type,   cast( null as integer) as text_length ,   cast( null as integer) as precision ,   cast( null as integer) as scale ,   cast( null as boolean) as is_enable,cast( null as boolean) as is_versionkey,cast( null as boolean) as is_nulable,cast( null as varchar(128)) as null_value 
  FROM (VALUES ('Z')) t1 (col1) LIMIT 0)
UNION SELECT 1, 1, 'RefID', 'uuid', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 2, 1, 'DeletionMark', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 3, 1, 'Code', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 4, 1, 'Description', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 5, 1, 'ЗагружаетсяИзИнтернета', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 6, 1, 'НаименованиеПолное', 'varchar', '50', NULL, NULL, true, false, true, NULL
UNION SELECT 7, 1, 'Наценка', 'decimal', NULL, '10', '2', true, false, true, NULL
UNION SELECT 8, 1, 'ОсновнаяВалюта', 'varchar', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 9, 1, 'ПараметрыПрописи', 'varchar', '200', NULL, NULL, true, false, true, NULL
UNION SELECT 10, 1, 'ФормулаРасчетаКурса', 'varchar', '100', NULL, NULL, true, false, true, NULL
UNION SELECT 11, 1, 'СпособУстановкиКурса', 'varchar', '500', NULL, NULL, true, false, true, NULL
UNION SELECT 12, 2, 'DIM_ВалютыRefID', 'uuid', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 13, 2, 'КодЯзыка', 'varchar', '10', NULL, NULL, true, false, true, NULL
UNION SELECT 14, 2, 'ПараметрыПрописи', 'varchar', '200', NULL, NULL, true, false, true, NULL
UNION SELECT 15, 3, 'RefID', 'uuid', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 16, 3, 'DeletionMark', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 17, 3, 'Code', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 18, 3, 'Description', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 19, 3, 'Контакт', 'varchar', '500', NULL, NULL, true, false, true, NULL
UNION SELECT 20, 4, 'RefID', 'uuid', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 21, 4, 'DeletionMark', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 22, 4, 'Code', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 23, 4, 'Description', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 24, 4, 'Описание', 'varchar', '255', NULL, NULL, true, false, true, NULL
UNION SELECT 25, 5, 'RefID', 'uuid', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 26, 5, 'DeletionMark', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 27, 5, 'Number', 'integer', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 28, 5, 'Posted', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 29, 5, 'Date', 'timestamp', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 30, 5, 'ДатаОтгрузки', 'timestamp', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 31, 5, 'Клиент', 'varchar', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 32, 5, 'ТипДоставки', 'varchar', '500', NULL, NULL, true, false, true, NULL
UNION SELECT 33, 5, 'ПримерСоставногоТипа', 'varchar', '36', NULL, NULL, true, false, true, NULL
UNION SELECT 34, 5, 'ПримерСоставногоТипа_ТипЗначения', 'varchar', '128', NULL, NULL, true, false, true, NULL
UNION SELECT 35, 6, 'FACT_ПродажиRefID', 'uuid', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 36, 6, 'Доставка', 'boolean', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 37, 6, 'Товар', 'varchar', NULL, NULL, NULL, true, false, true, NULL
UNION SELECT 38, 6, 'Колличество', 'decimal', NULL, '12', '0', true, false, true, NULL
UNION SELECT 39, 6, 'Цена', 'decimal', NULL, '16', '4', true, false, true, NULL
;
DROP TABLE tmp_codegen;

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


UPDATE dwh_session_state as c
SET name = t.name
FROM tmp_dwh_session_state as t
WHERE c.dwh_session_state_id = t.dwh_session_state_id;

INSERT INTO dwh_session_state (dwh_session_state_id, name)
SELECT * FROM tmp_dwh_session_state t
WHERE  NOT t.dwh_session_state_id in (SELECT dwh_session_state_id FROM dwh_session_state c);

DROP TABLE tmp_dwh_session_state;
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

do
$$
BEGIN
RAISE NOTICE 'Fill data_source';
END;
$$;

insert into data_source (data_source_id,name) 
SELECT 1, N'ods1c' 
WHERE NOT EXISTS(SELECT 1 FROM data_source WHERe data_source_id =1 );

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

UPDATE session_state as c
SET name = t.name
FROM tmp_session_state as t
WHERE c.session_state_id = t.session_state_id;

INSERT INTO session_state (session_state_id, name)
SELECT * FROM tmp_session_state t
WHERE  NOT t.session_state_id in (SELECT session_state_id FROM session_state c);

DROP TABLE tmp_session_state;
