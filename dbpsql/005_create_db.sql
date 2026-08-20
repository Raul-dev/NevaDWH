DROP DATABASE IF EXISTS newadwh_ods;
DROP DATABASE IF EXISTS newadwh_dwh;
DROP DATABASE IF EXISTS newadwh_landing;
CREATE DATABASE newadwh_ods ;
\c newadwh_ods;
CREATE DATABASE newadwh_landing ;
\c newadwh_landing;
CREATE USER db_owner PASSWORD 'db_owner';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_owner;
CREATE DATABASE newadwh_dwh ;
\c newadwh_dwh;

