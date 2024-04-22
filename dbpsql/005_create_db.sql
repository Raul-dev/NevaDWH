DROP DATABASE IF EXISTS nevadwh_ods;
DROP DATABASE IF EXISTS nevadwh_dwh;
DROP DATABASE IF EXISTS nevadwh_landing;
CREATE DATABASE nevadwh_ods ;
\c nevadwh_ods;
CREATE DATABASE nevadwh_landing ;
\c nevadwh_landing;
CREATE USER db_owner PASSWORD 'db_owner';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_owner;
CREATE DATABASE nevadwh_dwh ;
\c nevadwh_dwh;

