do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE "dwh_ArchiveTables"';
END;
$$;

CREATE OR REPLACE PROCEDURE "dwh_ArchiveTables" (
    par_dwh_session_id inout bigint DEFAULT NULL
)
AS $BODY$
DECLARE
    var_RowCount int;
    var_LocalRowCount  int;
BEGIN

    DELETE FROM odins.DIM_Валюты WHERE dwh_session_id = pat_dwh_session_id;

    DELETE FROM odins.DIM_Валюты_Представления WHERE dwh_session_id = par_dwh_session_id;

    DELETE FROM odins.DIM_Клиенты WHERE dwh_session_id = pat_dwh_session_id;

    DELETE FROM odins.DIM_Товары WHERE dwh_session_id = pat_dwh_session_id;

    DELETE FROM odins.FACT_Продажи WHERE dwh_session_id = pat_dwh_session_id;

    DELETE FROM odins.FACT_Продажи_Товары WHERE dwh_session_id = par_dwh_session_id;


    UPDATE dwh_session SET dwh_session_state_id = 6
    WHERE dwh_session_id = par_dwh_session_id;

END;

$BODY$
LANGUAGE plpgsql;
