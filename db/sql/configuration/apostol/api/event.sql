--------------------------------------------------------------------------------
-- api.on_confirm_email --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief EVENT: Confirm email address after verification
 * @param {uuid} pId - Verification code identifier
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.on_confirm_email (
  pId           uuid
) RETURNS       void
AS $$
DECLARE
  uUserId       uuid;
BEGIN
  SELECT userid INTO uUserId FROM db.verification_code WHERE id = pId;
  IF FOUND THEN
    PERFORM ExecuteObjectAction(GetClientByUserId(uUserId), GetAction('confirm'));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
