do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "dwh_SaveSessionState"';
END;
$$;
/*
call "dwh_SaveSessionState" (par_dwh_session_id =1, par_data_source_id =1, par_dwh_session_state_id=1, par_error_message 'ok' ) 
call public."dwh_SaveSessionState" (null::bigint, 1::smallint, 1::smallint, 'ok'::varchar(4000) ) 
call public."dwh_SaveSessionState" (1::bigint, 1::smallint, 1::smallint, 'ok'::varchar(4000) ) 
SELECT * FROM dwh_session
*/
CREATE OR REPLACE PROCEDURE "dwh_SaveSessionState" (
    par_dwh_session_id INOUT BIGINT DEFAULT NULL, 
    par_data_source_id IN smallint DEFAULT NULL, 
    par_dwh_session_state_id IN smallint DEFAULT NULL, 
    par_error_message IN varchar(4000) DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
BEGIN

    IF par_dwh_session_id IS NULL THEN
    
        SELECT  MAX(dwh_session_id) into par_dwh_session_id FROM dwh_session WHERE dwh_session_state_id = 1;
        IF NOT par_dwh_session_id IS NULL THEN
            RETURN;
        END IF;    

        INSERT INTO dwh_session (data_source_id,    dwh_session_state_id,    error_message)
        VALUES(par_data_source_id, par_dwh_session_state_id, par_error_message);
        
        SELECT currval(pg_get_serial_sequence('dwh_session','dwh_session_id')) into par_dwh_session_id;
        RETURN;
    
    ELSE
    
        UPDATE dwh_session
            SET 
                dwh_session_state_id = par_dwh_session_state_id,    
                error_message = par_error_message,
                create_session = CASE WHEN par_dwh_session_state_id = 2 THEN now() ELSE create_session END,
                dt_update = now()
        WHERE dwh_session_id = par_dwh_session_id;
    END IF;

END;

$BODY$
LANGUAGE plpgsql;
    