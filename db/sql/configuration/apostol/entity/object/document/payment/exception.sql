--------------------------------------------------------------------------------
-- FUNCTION PaymentCodeExists --------------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('9532d99f-2d7d-4935-a643-1bc0fe47e12d', 'ru', 'PaymentCodeExists', 'Платёж "%s" уже существует');
SELECT CreateExceptionResource('9532d99f-2d7d-4935-a643-1bc0fe47e12d', 'en', 'PaymentCodeExists', 'Payment "%s" already exists');

/**
 * @brief Raises exception: Payment with the given code already exists
 * @param {text} pCode - Code
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION PaymentCodeExists (
  pCode     text
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', format(GetResource('9532d99f-2d7d-4935-a643-1bc0fe47e12d'), pCode);
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

--------------------------------------------------------------------------------
-- FUNCTION IncorrectPaymentData -----------------------------------------------
--------------------------------------------------------------------------------

SELECT CreateExceptionResource('c605e42c-f7b9-41d5-9850-9052465f0b30', 'ru', 'IncorrectPaymentData', 'Неверные платежные данные');
SELECT CreateExceptionResource('c605e42c-f7b9-41d5-9850-9052465f0b30', 'en', 'IncorrectPaymentData', 'Incorrect payment data');

/**
 * @brief IncorrectPaymentData
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION IncorrectPaymentData (
) RETURNS   void
AS $$
BEGIN
  RAISE EXCEPTION 'ERR-40000: %', GetResource('c605e42c-f7b9-41d5-9850-9052465f0b30');
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;
