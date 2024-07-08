
CREATE OR REPLACE FUNCTION  "fn_GetMinDate"()
RETURNS timestamp
AS $BODY$
BEGIN
  RETURN make_date(1900, 1 , 1);
END;
$BODY$
LANGUAGE plpgsql;

