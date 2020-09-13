--------------------------------------------------------------------------------
-- FUNCTION ClientCodeExists  --------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ClientCodeExists (
  pCode		varchar
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Клиент с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
