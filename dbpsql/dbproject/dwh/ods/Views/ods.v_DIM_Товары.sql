do
$$
BEGIN
RAISE NOTICE 'Create view ods.DIM_Товары';
END;
$$;

DROP VIEW IF EXISTS ods."v_DIM_Товары";

CREATE VIEW ods."v_DIM_Товары" 
AS
SELECT
    -1 * ods_id::bigint AS id,
    0::bigint session_id,
    'ods1c'::varchar(128) AS source_name,
    nkey,
    NULL::uuid AS vkey,
    now()::timestamp without time zone AS start_date,
    public."fn_GetMaxDate"()::timestamp without time zone AS end_date,
    "RefID",
    "DeletionMark",
    "Code",
    "Description",
    "Описание",
    0::bigint AS session_id_update,
    dt_update::timestamp without time zone,
    dt_create::timestamp without time zone
FROM ods."odins_DIM_Товары";

