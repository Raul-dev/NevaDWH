
CREATE OR REPLACE FUNCTION  "fn_GetMaxDate"()
RETURNS timestamp
AS $BODY$
BEGIN
  RETURN make_date(2100, 1 , 1);
END;
$BODY$
LANGUAGE plpgsql;

