do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE mq.rb_SaveSessionState';

END;
$$;

CREATE OR REPLACE PROCEDURE mq."rb_SaveSessionState" (
    par_session_id inout bigint DEFAULT NULL,
    par_data_source_id in smallint DEFAULT 1,
    par_session_state_id in smallint DEFAULT 1,
    par_error_message in varchar(4000) DEFAULT NULL
)
AS $BODY$
BEGIN
    IF par_session_id IS NULL THEN

        INSERT INTO mq.session (data_source_id, session_state_id, error_message)
        VALUES (par_data_source_id, par_session_state_id, par_error_message)
        RETURNING session_id INTO par_session_id;

        INSERT INTO mq.session_log (session_id, session_state_id, error_message)
        VALUES (par_session_id, par_session_state_id, par_error_message);

        RETURN;
    ELSE
        UPDATE mq.session
        SET data_source_id = par_data_source_id,
            session_state_id = par_session_state_id,
            error_message = par_error_message,
            updated_at = now()
        WHERE session_id = par_session_id;

        INSERT INTO mq.session_log (session_id, session_state_id, error_message)
        VALUES (par_session_id, par_session_state_id, par_error_message);
    END IF;
END;

$BODY$
LANGUAGE plpgsql;
