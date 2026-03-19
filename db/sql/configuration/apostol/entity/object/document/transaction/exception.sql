--------------------------------------------------------------------------------
-- FUNCTION TransactionCodeExists ----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('c9108a56-7d77-4221-86f8-bbfae638f386', 'ru', 'TransactionCodeExists', 'Транзакция с кодом "%" уже существует');
SELECT CreateExceptionResource('c9108a56-7d77-4221-86f8-bbfae638f386', 'en', 'TransactionCodeExists', 'Transaction "%s" already exists');

/**
 * @brief Raises exception: Transaction with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION TransactionCodeExists (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('c9108a56-7d77-4221-86f8-bbfae638f386'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION TariffNotFound -----------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('779c88af-7fdc-4819-8a11-1df1b9eaec3a', 'ru', 'TariffNotFound', 'Тариф услуги "%s" в валюте "%s" с меткой "%s" не найден');
SELECT CreateExceptionResource('779c88af-7fdc-4819-8a11-1df1b9eaec3a', 'en', 'TariffNotFound', 'The tariff for the service "%s" and currency "%s" tag "%s" was not found');

/**
 * @brief Raises exception: Transaction not found
 * @param {text} pService - Service
 * @param {text} pCurrency - Currency identifier
 * @param {text} pTag - Tag
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION TariffNotFound (
  pService  text,
  pCurrency	text,
  pTag      text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('779c88af-7fdc-4819-8a11-1df1b9eaec3a'), pService, pCurrency, pTag);
END;
$$ LANGUAGE plpgsql STRICT;
