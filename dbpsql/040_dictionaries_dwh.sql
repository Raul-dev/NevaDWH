\c nevadwh_dwh;


INSERT INTO data_source (data_source_id,name) 
SELECT 1, N'ods1c';


INSERT INTO session_state (session_state_id, name)
VALUES
(1, N'Начало обработки Etl'),
(2, N'Завершение обработки Etl'),
(3, N'Ошибка обработки Etl');
