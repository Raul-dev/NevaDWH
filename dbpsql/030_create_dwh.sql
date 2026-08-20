\c newadwh_dwh;

CREATE extension postgres_fdw;

CREATE SERVER client_ods FOREIGN DATA WRAPPER postgres_fdw OPTIONS (dbname 'newadwh_ods', host '127.0.0.1', port '5432');

CREATE USER MAPPING FOR postgres SERVER client_ods OPTIONS ( USER 'postgres', PASSWORD 'postgres');

CREATE SCHEMA IF NOT EXISTS bulk;
CREATE SCHEMA IF NOT EXISTS fdw;
CREATE SCHEMA IF NOT EXISTS ods;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS target;
