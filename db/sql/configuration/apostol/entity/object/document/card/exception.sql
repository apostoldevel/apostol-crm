--------------------------------------------------------------------------------
-- FUNCTION CardCodeExists -----------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Raises exception: Card with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CardCodeExists (
  pCode		text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Карта с кодом "%" уже существует.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION CardNotAssociated --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief Raises exception: Card is not associated with a client
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CardNotAssociated (
  pCode     text
) RETURNS	void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: Карта "%" не связана с клиентом.', pCode;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
