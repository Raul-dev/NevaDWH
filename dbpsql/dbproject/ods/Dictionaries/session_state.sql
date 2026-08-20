
do
$$
BEGIN
RAISE NOTICE 'Fill data_source';
END;
$$;

insert into mq.data_source (data_source_id,name)
SELECT 1, N'ods1c'
WHERE NOT EXISTS(SELECT 1 FROM mq.data_source WHERe data_source_id =1 );

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

UPDATE mq.session_state as c
SET name = t.name
FROM tmp_session_state as t
WHERE c.session_state_id = t.session_state_id;

INSERT INTO mq.session_state (session_state_id, name)
SELECT * FROM tmp_session_state t
WHERE  NOT t.session_state_id in (SELECT session_state_id FROM mq.session_state c);

DROP TABLE tmp_session_state;
