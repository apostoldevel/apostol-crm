--------------------------------------------------------------------------------
-- FUNCTION UnknownProtocol  --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION UnknownProtocol (
  pProtocol text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Неизвестный протокол: "%".', pProtocol;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
