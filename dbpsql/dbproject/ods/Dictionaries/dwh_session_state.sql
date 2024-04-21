
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
