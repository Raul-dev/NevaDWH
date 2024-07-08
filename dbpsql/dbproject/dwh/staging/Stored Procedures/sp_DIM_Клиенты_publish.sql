do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE staging."sp_DIM_Клиенты_p"';
END;
$$;

CREATE OR REPLACE PROCEDURE staging."sp_DIM_Клиенты_p" (
    par_session_id in int DEFAULT NULL, 
    par_RowCount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_RowCount INTEGER;
BEGIN

    UPDATE target."DIM_Клиенты" AS trg SET
        session_id = stg.session_id,
        start_date = stg.start_date,
        end_date = stg.end_date,
        session_id_update = stg.session_id_update,
        dt_update = stg.dt_update,
        "RefID" = stg."RefID",
        "DeletionMark" = stg."DeletionMark",
        "Code" = stg."Code",
        "Description" = stg."Description",
        "Контакт" = stg."Контакт"
    FROM staging."DIM_Клиенты" stg
    WHERE stg.id = trg.id;

    INSERT INTO target."DIM_Клиенты" (
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        session_id_update,
        dt_update,
        dt_create,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Контакт"
    )
    SELECT
        id,
        session_id,
        source_name,
        nkey,
        vkey,
        start_date,
        end_date,
        session_id_update,
        dt_update,
        now() as dt_create,
        "RefID",
        "DeletionMark",
        "Code",
        "Description",
        "Контакт"
    FROM staging."DIM_Клиенты"
    WHERE staging_id = id;

END;

$BODY$
LANGUAGE plpgsql;
