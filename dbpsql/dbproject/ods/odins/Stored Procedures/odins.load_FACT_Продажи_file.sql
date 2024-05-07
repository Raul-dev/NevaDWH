do
$$
BEGIN
RAISE NOTICE 'CREATE PROCEDURE odins."load_FACT_Продажи_file"';
END;
$$;

CREATE OR REPLACE PROCEDURE odins."load_FACT_Продажи_file" (
    par_session_id in bigint DEFAULT NULL, 
    par_rowcount inout int DEFAULT NULL 
)
AS $BODY$
DECLARE
    var_rowcount int;
BEGIN

    DROP TABLE IF EXISTS "FACT_Продажи_tmp1";
    
END;

$BODY$
LANGUAGE plpgsql;
