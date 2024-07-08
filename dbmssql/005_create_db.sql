DROP DATABASE IF EXISTS nevadwh_ods;
CREATE DATABASE nevadwh_ods ;
\c nevadwh_ods;
CREATE USER db_owner PASSWORD 'db_owner';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_owner;

