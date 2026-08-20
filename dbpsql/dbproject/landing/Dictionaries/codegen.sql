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