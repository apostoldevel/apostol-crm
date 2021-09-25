--------------------------------------------------------------------------------
-- FUNCTION AccountCodeExists --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('86615dbe-5cbc-45fc-bde8-b7afe8d5f236', 'ru', 'AccountCodeExists', 'Счёт "%s" уже существует');
SELECT CreateExceptionResource('86615dbe-5cbc-45fc-bde8-b7afe8d5f236', 'en', 'AccountCodeExists', 'Account "%s" already exists');

CREATE OR REPLACE FUNCTION AccountCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('86615dbe-5cbc-45fc-bde8-b7afe8d5f236'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION AccountNotFound ----------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'ru', 'AccountNotFound', 'Счёт "%s" не найден');
SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'en', 'AccountNotFound', 'Account "%s" not found');

CREATE OR REPLACE FUNCTION AccountNotFound (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('6750236e-5328-474d-968c-c0a15e40ffe4'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION AccountNotAssociated -----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'ru', 'AccountNotFound', 'Счёт "%s" не связан с клиентом');
SELECT CreateExceptionResource('6750236e-5328-474d-968c-c0a15e40ffe4', 'en', 'AccountNotFound', 'Account "%s" not affiliated with the client');

CREATE OR REPLACE FUNCTION AccountNotAssociated (
  pCode     text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('6750236e-5328-474d-968c-c0a15e40ffe4'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
