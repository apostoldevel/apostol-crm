--------------------------------------------------------------------------------
-- FUNCTION IdentityExists -----------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('64ecc851-b939-461e-86f4-37db5cfa4d4e', 'ru', 'IdentityExists', 'Удостоверение личности "%s" уже существует');
SELECT CreateExceptionResource('64ecc851-b939-461e-86f4-37db5cfa4d4e', 'en', 'IdentityExists', 'Identity "%s" already exists');

/**
 * @brief IdentityExists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IdentityExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('64ecc851-b939-461e-86f4-37db5cfa4d4e'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION IdentityNotFound ---------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('ba0e117b-1a82-4375-8f0c-5eee3b49aff1', 'ru', 'IdentityNotFound', 'Удостоверение личности "%s" не найдено');
SELECT CreateExceptionResource('ba0e117b-1a82-4375-8f0c-5eee3b49aff1', 'en', 'IdentityNotFound', 'Identity "%s" not found');

/**
 * @brief Raises exception: Identity document not found
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IdentityNotFound (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('ba0e117b-1a82-4375-8f0c-5eee3b49aff1'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION IdentityNotAssociated ----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('d747e4ab-cb4d-4600-9432-9eee853c6c8c', 'ru', 'IdentityNotAssociated', 'Удостоверение личности "%s" не связано с клиентом');
SELECT CreateExceptionResource('d747e4ab-cb4d-4600-9432-9eee853c6c8c', 'en', 'IdentityNotAssociated', 'Identity "%s" not affiliated with the client');

/**
 * @brief Raises exception: Identity document is not associated with a client
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IdentityNotAssociated (
  pCode     text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('d747e4ab-cb4d-4600-9432-9eee853c6c8c'), pCode);
END;
$$ LANGUAGE plpgsql;
