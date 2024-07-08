do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "dwh_ArchiveTables"';
END;
$$;

CREATE OR REPLACE PROCEDURE "dwh_ArchiveTables" (
    par_dwh_session_id inout INT DEFAULT NULL
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
    var_LocalRowCount  INTEGER;
BEGIN

   
    
        UPDATE dwh_session SET dwh_session_state_id = 6
    WHERE dwh_session_id = par_dwh_session_id;
    
END;

$BODY$
LANGUAGE plpgsql;
