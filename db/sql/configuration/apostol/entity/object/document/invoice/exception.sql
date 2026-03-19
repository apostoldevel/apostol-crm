--------------------------------------------------------------------------------
-- FUNCTION AccountCodeExists --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('b7c0bf70-57f6-45af-988f-5eed0b55d1d7', 'ru', 'InvoiceCodeExists', 'Счёт с кодом "%s" уже существует');
SELECT CreateExceptionResource('b7c0bf70-57f6-45af-988f-5eed0b55d1d7', 'en', 'InvoiceCodeExists', 'Invoice "%s" already exists');

/**
 * @brief Raises exception: Invoice with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InvoiceCodeExists (
  pCode        text
) RETURNS    void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('b7c0bf70-57f6-45af-988f-5eed0b55d1d7'), pCode);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION InvalidInvoiceAmount -----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('485ab91b-3160-4361-8bc0-040dda4ea9e8', 'ru', 'InvalidInvoiceAmount', 'Неверная сумма заказа');
SELECT CreateExceptionResource('485ab91b-3160-4361-8bc0-040dda4ea9e8', 'en', 'InvalidInvoiceAmount', 'Invalid order amount');

/**
 * @brief InvalidInvoiceAmount
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InvalidInvoiceAmount (
) RETURNS    void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('485ab91b-3160-4361-8bc0-040dda4ea9e8');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION InvalidInvoiceBalance ----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('95601982-0329-4ce8-aca2-0c59e851bea5', 'ru', 'InvalidInvoiceBalance', 'На балансе недостаточно средств для оплаты счёта. Пожалуйста, пополните свой баланс');
SELECT CreateExceptionResource('95601982-0329-4ce8-aca2-0c59e851bea5', 'en', 'InvalidInvoiceBalance', 'There are not enough funds on the balance to pay the invoice. Please top up your balance');

/**
 * @brief InvalidInvoiceBalance
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION InvalidInvoiceBalance (
) RETURNS    void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('95601982-0329-4ce8-aca2-0c59e851bea5');
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- FUNCTION UnsupportedInvoiceType ---------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('7aa2b7ea-f69c-4da7-bd8b-5364b743feff', 'ru', 'UnsupportedInvoiceType', 'Неподдерживаемый тип счета-фактуры');
SELECT CreateExceptionResource('7aa2b7ea-f69c-4da7-bd8b-5364b743feff', 'en', 'UnsupportedInvoiceType', 'Unsupported invoice type');

/**
 * @brief UnsupportedInvoiceType
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION UnsupportedInvoiceType (
) RETURNS    void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('7aa2b7ea-f69c-4da7-bd8b-5364b743feff');
END;
$$ LANGUAGE plpgsql;
