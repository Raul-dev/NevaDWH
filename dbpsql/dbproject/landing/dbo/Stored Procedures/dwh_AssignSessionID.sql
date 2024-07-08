do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "dwh_AssignSessionID"';
END;
$$;

-- SELECT * FROM dwh_processing_details
-- call public."dwh_AssignSessionID" (null, null)
CREATE OR REPLACE PROCEDURE "dwh_AssignSessionID" (
    INOUT par_dwh_session_id bigint DEFAULT NULL::bigint,
    INOUT par_rowcount bigint DEFAULT NULL::bigint,
    INOUT par_create_session timestamp DEFAULT NULL::timestamp
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
    var_LocalRowCount INTEGER;
BEGIN

    par_rowcount:= 0;
    IF NOT par_dwh_session_id IS NULL AND par_dwh_session_id != -1 THEN

        SELECT INTO par_dwh_session_id, par_rowcount, par_create_session
        FROM (
            SELECT s.dwh_session_id, sum(row_count) as row_count, MAX(s.create_session) AS create_session
            FROM dwh_session s
                INNER JOIN dwh_processing_details p ON p.dwh_session_id = s.dwh_session_id
            WHERE dwh_session_state_id = 2 AND s.dwh_session_id = par_dwh_session_id
            GROUP BY s.dwh_session_id
        ) s;
        RETURN ;
    END IF;

    SELECT create_session INTO par_create_session FROM dwh_session WHERE dwh_session_id = par_dwh_session_id;
END;

$BODY$
LANGUAGE plpgsql;
