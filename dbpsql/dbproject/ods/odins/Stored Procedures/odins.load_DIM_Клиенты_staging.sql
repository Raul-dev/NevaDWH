do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_DIM_Клиенты_staging"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_DIM_Клиенты_staging" (
    par_session_id in bigint DEFAULT NULL, 
    par_rowcount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_rowcount int;
BEGIN

    DROP TABLE IF EXISTS "DIM_Клиенты_tmp1";

END;

$BODY$
LANGUAGE plpgsql;
