--------------------------------------------------------------------------------
-- CONFIRMATION ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CreateConfirmation ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Create a payment confirmation record
 * @param {uuid} pAgent - Payment agent (reference) identifier
 * @param {uuid} pPayment - Payment document identifier
 * @param {jsonb} pData - Confirmation data from payment provider
 * @return {uuid} - Confirmation record identifier
 * @throws ObjectNotFound - When agent or payment not found
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION CreateConfirmation (
  pAgent        uuid,
  pPayment      uuid,
  pData         jsonb
) RETURNS       uuid
AS $$
DECLARE
  uId           uuid;
BEGIN
  PERFORM FROM db.agent WHERE id = pAgent;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('agent', 'id', pAgent);
  END IF;

  PERFORM FROM db.payment WHERE id = pPayment;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('payment', 'id', pPayment);
  END IF;

  INSERT INTO db.confirmation (agent, payment, data)
  VALUES (pAgent, pPayment, pData)
  ON CONFLICT (payment, validfromdate, validtodate) DO UPDATE SET data = pData
  RETURNING id INTO uId;

  RETURN uId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
