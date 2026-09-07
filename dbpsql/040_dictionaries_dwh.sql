\c newadwh_dwh;


do
$$
BEGIN
  RAISE NOTICE 'Fill data_source';
END;
$$;

INSERT INTO mq.data_source (data_source_id, name)
SELECT 1, N'ods1c'
WHERE NOT EXISTS (SELECT 1 FROM mq.data_source WHERE data_source_id = 1);

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_session_state
(
  session_state_id smallint,
  name VARCHAR(100)
);

INSERT INTO tmp_session_state (session_state_id, name) VALUES
(1, N'Начало обработки Etl'),
(2, N'Завершение обработки Etl'),
(3, N'Ошибка обработки Etl');

UPDATE mq.session_state AS c
SET name = t.name
FROM tmp_session_state AS t
WHERE c.session_state_id = t.session_state_id;

INSERT INTO mq.session_state (session_state_id, name)
SELECT t.session_state_id, t.name
FROM tmp_session_state t
WHERE NOT t.session_state_id IN (SELECT session_state_id FROM mq.session_state c);

DROP TABLE tmp_session_state;
