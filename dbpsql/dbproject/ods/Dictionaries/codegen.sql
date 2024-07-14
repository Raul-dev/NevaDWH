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