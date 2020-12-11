--------------------------------------------------------------------------------
-- InitConfiguration -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfiguration()
RETURNS     void
AS $$
DECLARE
  nDocument   numeric;
  nReference  numeric;
BEGIN
  -- Документ

  nDocument := GetClass('document');

  -- Справочник

  nReference := GetClass('reference');

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
