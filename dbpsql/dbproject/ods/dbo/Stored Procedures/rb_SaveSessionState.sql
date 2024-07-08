do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE public."rb_SaveSessionState"';

END;
$$;

CREATE OR REPLACE PROCEDURE public."rb_SaveSessionState" (
    par_session_id inout bigint DEFAULT NULL, 
    par_data_source_id in smallint = 1,
    par_session_state_id in smallint = 1,
    par_error_message in varchar(4000) DEFAULT NULL 
)
AS $BODY$
BEGIN
    IF par_session_id IS NULL THEN

        INSERT INTO "session" (data_source_id, session_state_id, error_message)
        VALUES(par_data_source_id, par_session_state_id, par_error_message);
        
        SELECT currval(pg_get_serial_sequence('session', 'session_id')) INTO par_session_id;
        RETURN;
    ELSE
        UPDATE "session"
        SET data_source_id = par_data_source_id,
            session_state_id = par_session_state_id,
            dt_update = now()
        WHERE session_id = par_session_id;
    END IF;
END;

$BODY$
LANGUAGE plpgsql;
