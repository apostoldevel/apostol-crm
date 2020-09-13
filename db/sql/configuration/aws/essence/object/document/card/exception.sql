CREATE OR REPLACE FUNCTION CardCodeExists (
  pCode		varchar
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Карта с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
