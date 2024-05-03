
DO
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "sp_SaveSessionState"';
END;
$$;
/*
call public."sp_SaveSessionState" (null::bigint, 1::bigint, 1::bigint, 1::smallint, 1::smallint, now()::timestamp, null::varchar(4000) ) 
SELECT * FROM session
SELECT COALESE(par_create_session, now())
*/
CREATE OR REPLACE PROCEDURE "sp_SaveSessionState" (
    par_session_id INOUT bigint DEFAULT NULL, 
    par_dwh_session_id IN bigint DEFAULT NULL, 
    par_rows_count  IN bigint DEFAULT NULL, 
    par_data_source_id IN smallint DEFAULT NULL, 
    par_session_state_id IN smallint DEFAULT NULL, 
    par_create_session IN timestamp DEFAULT NULL, 
    par_error_message IN varchar(4000) DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
    
BEGIN

    IF par_session_id IS NULL THEN
        SELECT COALESCE(par_create_session, now()) into par_create_session;
        SELECT COALESCE(par_session_state_id, 1) into par_session_state_id;
        INSERT INTO session (data_source_id, session_state_id, rows_count, create_session, dwh_session_id)
        VALUES(par_data_source_id, par_session_state_id, par_rows_count, par_create_session, par_dwh_session_id);
        
        SELECT currval(pg_get_serial_sequence('session','session_id')) into par_session_id;
        RETURN;
    ELSE
    
        UPDATE session
            SET 
                session_state_id = par_session_state_id,    
                error_message = par_error_message,
                dt_update = now()
        WHERE session_id = par_session_id;
    END IF;

END;

$BODY$
LANGUAGE plpgsql;
    