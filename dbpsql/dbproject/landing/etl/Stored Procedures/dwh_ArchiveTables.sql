do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE etl.dwh_ArchiveTables';
END;
$$;

CREATE OR REPLACE PROCEDURE etl.dwh_ArchiveTables (
    par_dwh_session_id inout int DEFAULT NULL
)
AS $BODY$
DECLARE
    var_RowCount int;
    var_LocalRowCount  int;
BEGIN



    UPDATE etl.dwh_session SET dwh_session_state_id = 6
    WHERE dwh_session_id = par_dwh_session_id;

END;

$BODY$
LANGUAGE plpgsql;
