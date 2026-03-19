--------------------------------------------------------------------------------
-- FUNCTION ClientCodeExists  --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Raises exception: Company with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION ClientCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Сотрудник с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION AccountNotClient  --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief AccountNotClient
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION AccountNotClient (
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Учётная запись не принадлежит сотруднику.';
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION EmailAddressNotSet -------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EmailAddressNotSet
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EmailAddressNotSet (
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Не задан адрес электронной почты.';
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION EmailAddressNotVerified --------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief EmailAddressNotVerified
 * @param {text} pEmail - Email address
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION EmailAddressNotVerified (
  pEmail    text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Адрес электронной почты "%" не подтвержден участником.', pEmail;
END;
$$ LANGUAGE plpgsql;
