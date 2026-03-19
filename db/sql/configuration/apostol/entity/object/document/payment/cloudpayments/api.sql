--------------------------------------------------------------------------------
-- api.cloudpayments_callback --------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.cloudpayments_callback
 * @param {jsonb} pPayload - JSON request payload
 * @return {int}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.cloudpayments_callback (
  pPayload          jsonb
) RETURNS           int
AS $$
DECLARE
  p                 record;

  vMessage          text;
  vContext          text;
BEGIN
  SELECT * INTO p FROM jsonb_to_record(pPayload) AS x("method" text);

  PERFORM WriteToEventLog('D', 0, 'cloudpayments', pPayload::text);

  RETURN 0;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
  RETURN 1;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- api.cloudpayments_done ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.cloudpayments_done
 * @param {uuid} pRequest - Request
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.cloudpayments_done (
  pRequest      uuid
) RETURNS       void
AS $$
DECLARE
  q             record;
  r             record;
  d             record;
  p             record;
  m             record;

  uCard         uuid;
  uAgent        uuid;
  uPayment      uuid;
  uInvoice      uuid;

  payload       jsonb;

  vContent      text;
  vMessage      text;
  vContext      text;
BEGIN
  SELECT agent, command, profile, resource, data INTO q FROM http.request WHERE id = pRequest;
  SELECT status, status_text, content INTO r FROM http.response WHERE id = pRequest;

  SELECT * INTO d FROM jsonb_to_record(q.data) AS x(session text, userid uuid, "payment" uuid, card uuid, invoice uuid);

  IF d.session IS NOT NULL THEN
    PERFORM SessionIn(d.session);
  END IF;

  vContent := convert_from(r.content, 'utf8');
  payload := vContent::jsonb;

  IF coalesce(r.status, 0) = 200 THEN

    SELECT * INTO p FROM jsonb_to_record(payload) AS x("Success" boolean, "Message" text, "ErrorCode" text, "Model" jsonb);

    IF q.command IN ('/payments/cards/charge', '/payments/cards/auth', '/payments/confirm', '/payments/cancel', '/payments/refund') THEN
      SELECT * INTO m FROM jsonb_to_record(p."Model") AS x("Status" text, "StatusCode" int, "TransactionId" text, "AccountId" uuid, "Reason" text, "CardHolderMessage" text);

      uAgent := GetAgent('cloudpayments.agent');
      uPayment := d."payment";

      IF uPayment IS NOT NULL THEN
        UPDATE db.payment SET payment_id = m."TransactionId" WHERE id = uPayment AND payment_id IS NULL;

        IF m."Status" = 'AwaitingAuthentication' THEN

          IF GetObjectStateCode(uPayment) = 'waiting' THEN
--             IF p.confirmation IS NOT NULL THEN
--               IF p.confirmation->>'type' = 'redirect' THEN
--                 PERFORM CreateConfirmation(uAgent, uPayment, p.confirmation);
--               END IF;
--             END IF;
          END IF;

        ELSIF m."Status" = 'Authorized' THEN

          IF GetObjectStateCode(uPayment) = 'authorized' THEN
            IF GetObjectTypeCode(uPayment) = 'validation.cloudpayments' THEN
              PERFORM DoAction(uPayment, 'cancel'); --> canceling
            ELSE
              PERFORM DoAction(uPayment, 'continue'); --> waiting
            END IF;
          END IF;

        ELSIF m."Status" = 'Completed' THEN

          IF GetObjectStateCode(uPayment) IN ('waiting', 'confirming', 'refunding') THEN
            PERFORM DoAction(uPayment, 'done'); --> confirmed | refunded
          END IF;

          SELECT invoice INTO uInvoice FROM db.payment WHERE id = uPayment;

          IF uInvoice IS NOT NULL THEN
            IF IsEnabled(uInvoice) THEN
              PERFORM DoDisable(uInvoice);
            END IF;
          END IF;

        ELSIF m."Status" = 'Cancelled' THEN

          IF GetObjectStateCode(uPayment) = 'canceling' THEN

            IF GetObjectTypeCode(uPayment) = 'validation.cloudpayments' THEN

              SELECT card INTO uCard FROM db.payment WHERE id = uPayment;

--               PERFORM SetCardData(uCard, uAgent, null, m.id, null, p.payment_method);
--
--               IF IsCreated(uCard) THEN
--                 UPDATE db.card SET binding = m.id WHERE id = uCard;
--
--                 PERFORM DoEnable(uCard);
--                 PERFORM EditCard(uCard, pSequence => 0);
--               END IF;
            END IF;

            PERFORM DoAction(uPayment, 'done'); --> canceled
          END IF;

        ELSIF m."Status" = 'Declined' THEN

          IF GetObjectStateCode(uPayment) = 'waiting' THEN
            PERFORM DoAction(uPayment, 'reject'); --> declined
          END IF;
        END IF;
      END IF;

    ELSIF q.command = '/kkt/receipt' THEN

      uInvoice := d.invoice;

      IF uInvoice IS NOT NULL AND p."Success" THEN
        SELECT * INTO m FROM jsonb_to_record(p."Model") AS x("Id" text, "ReceiptLocalUrl" text);
        PERFORM SetObjectData(uInvoice, 'text', 'kkt', m."ReceiptLocalUrl");
      END IF;

    END IF;

  ELSE

    SELECT * INTO p FROM jsonb_to_record(payload) AS x(id uuid, type text, code text, description text);

    uPayment := d."payment";

    IF uPayment IS NOT NULL THEN
      IF p.description IS NOT NULL THEN
        PERFORM YK_Error(uPayment, r.status, 'cloudpayments', p.description);
      ELSE
        PERFORM YK_Error(uPayment, r.status, 'cloudpayments', coalesce(vContent, r.status_text));
      END IF;

      PERFORM DoAction(uPayment, 'fail');
    ELSE
      PERFORM WriteToEventLog('E', r.status, q.agent, coalesce(vContent, r.status_text));
    END IF;

  END IF;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- api.cloudpayments_fail ------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.cloudpayments_fail
 * @param {uuid} pRequest - Request
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.cloudpayments_fail (
  pRequest          uuid
) RETURNS           void
AS $$
DECLARE
  r                 record;
  d                 record;
BEGIN
  SELECT method, resource, agent, command, error, data INTO r
    FROM http.request
   WHERE id = pRequest;

  SELECT * INTO d FROM jsonb_to_record(r.data) AS x(session text, userid uuid);

  PERFORM WriteToEventLog('E', 300, r.agent, format('[%s] %s', r.command, r.error));
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;
