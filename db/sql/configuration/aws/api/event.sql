--------------------------------------------------------------------------------
-- api.on_confirm_email --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * СОБЫТИЕ: Подтверждает адрес электронной почты.
 * @param {uuid} pId - Идентификатор кода подтверждения
 * @return {record}
 */
CREATE OR REPLACE FUNCTION api.on_confirm_email (
  pId           uuid
) RETURNS       void
AS $$
DECLARE
  uUserId       uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.verification_code WHERE id = pId;
  IF found THEN
    PERFORM ExecuteObjectAction(GetClientByUserId(uUserId), GetAction('confirm'));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
