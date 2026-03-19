--------------------------------------------------------------------------------
-- api.yookassa_callback -------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.yookassa_callback
 * @param {jsonb} pPayload - JSON request payload
 * @return {bool}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.yookassa_callback (
  pPayload          jsonb
) RETURNS           bool
AS $$
DECLARE
  p                 record;
  o                 record;
  m                 record;
  e                 record;
  i                 record;

  uCard             uuid;
  uAgent            uuid;
  uUserId           uuid;
  uLocale           uuid;
  uPayment          uuid;
  uAccount          uuid;

  nAmount           numeric;

  vCode             text;
  vTitle            text;
  vSession          text;
  vStateCode        text;
  vOAuthClient      text;
  vOAuthSecret      text;

  vMessage          text;
  vContext          text;
BEGIN
  SELECT * INTO p FROM jsonb_to_record(pPayload) AS x(type text, event text, object jsonb);
  SELECT * INTO o FROM jsonb_to_record(p.object) AS x(id uuid, payment_id text, paid boolean, test boolean, amount jsonb, status text, metadata jsonb, recipient jsonb, created_at timestamp, refundable boolean, captured_at timestamp, income_amount jsonb, payment_method jsonb, refunded_amount jsonb, authorization_details jsonb);

  IF o.payment_id IS NOT NULL THEN
    SELECT id INTO uPayment FROM db.payment WHERE payment_id = o.payment_id;
  ELSE
    uPayment := o.metadata->>'payment';
  END IF;

  IF uPayment IS NULL THEN
    RETURN false;
  END IF;

  IF p.event = 'payment.update' THEN
    PERFORM YK_Payment(uPayment);
    RETURN true;
  END IF;

  SELECT client, invoice, metadata INTO e FROM db.payment WHERE id = uPayment;
  SELECT userid INTO uUserId FROM db.client WHERE id = e.client;

  SELECT a.code, a.secret INTO vOAuthClient, vOAuthSecret FROM oauth2.audience a WHERE a.application = GetApplication('system');

  IF FOUND THEN
    vSession := SignIn(CreateSystemOAuth2(), vOAuthClient, vOAuthSecret);

    IF vSession IS NULL THEN
      PERFORM AuthenticateError(GetErrorMessage());
    END IF;

    PERFORM SubstituteUser(GetUser('apibot'), vOAuthSecret);

    SELECT locale INTO uLocale FROM db.profile WHERE userid = uUserId AND scope = current_scope();

    IF FOUND THEN
      PERFORM SetLocale(uLocale);
    END IF;
  END IF;

  uAgent := GetAgent('yookassa.agent');

  IF p.event = 'payment.waiting_for_capture' THEN

    vStateCode := GetObjectStateCode(uPayment);

    IF vStateCode = 'pending' THEN
      IF GetObjectTypeCode(uPayment) = 'validation.yookassa' THEN
        PERFORM DoAction(uPayment, 'cancel'); --> canceling
      ELSE
        PERFORM DoAction(uPayment, 'continue'); --> waiting_for_capture
      END IF;
    END IF;

  ELSIF p.event = 'payment.succeeded' THEN

    vStateCode := GetObjectStateCode(uPayment);

    IF vStateCode IN ('pending', 'confirming', 'refunding') THEN
      PERFORM CreditingPayment(uPayment);

      PERFORM DoAction(uPayment, 'done'); --> succeeded

      IF e.invoice IS NOT NULL THEN
        IF IsEnabled(e.invoice) AND GetObjectTypeCode(e.invoice) = 'top-up.invoice' THEN
          SELECT client, currency, amount INTO i FROM db.invoice WHERE id = e.invoice;

          uAccount := GetClientAccount(i.client, i.currency, '100');
          nAmount := coalesce(GetBalance(uAccount), 0.00);

          IF i.amount <= nAmount THEN
            PERFORM DoDisable(e.invoice);
--             IF NOT o.test THEN
--               PERFORM CP_Kkt(e.invoice);
--             END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    IF vStateCode = 'refunding' THEN
      PERFORM DoAction(uPayment, 'done'); --> refunded
    END IF;

  ELSIF p.event = 'payment.canceled' THEN

    vStateCode := GetObjectStateCode(uPayment);

    IF vStateCode = 'canceling' THEN

      vCode := GetObjectTypeCode(uPayment);

      IF vCode = 'validation.yookassa' THEN
        SELECT * INTO m FROM jsonb_to_record(o.payment_method) AS x(id text, type text, saved boolean);

        IF m.type = 'bank_card' AND m.saved THEN
          SELECT card INTO uCard FROM db.payment WHERE id = uPayment;

          PERFORM SetCardData(uCard, uAgent, null, m.id, null, o.payment_method);

          IF IsCreated(uCard) THEN
            UPDATE db.card SET binding = m.id WHERE id = uCard;

            PERFORM DoEnable(uCard);
            PERFORM EditCard(uCard, pSequence => 0);
          END IF;
        END IF;
      END IF;

      PERFORM DoAction(uPayment, 'done'); --> canceled

    ELSIF vStateCode = 'pending' THEN

      vCode := GetObjectTypeCode(uPayment);

      IF vCode = 'validation.yookassa' THEN
        SELECT card INTO uCard FROM db.payment WHERE id = uPayment;

        PERFORM ClearCardData(uCard, uAgent);

        IF IsCreated(uCard) THEN
          PERFORM DoDisable(uCard);
        END IF;
      ELSIF vCode = 'reserve.yookassa' THEN
        vTitle := 'Зарядная сессия прервана';
        vMessage := format('Не удалось зарезервировать %s %s для начала зарядной сессии.', o.amount->>'value', o.amount->>'currency');

        IF uUserId IS NOT NULL THEN
          PERFORM pg_notify('urgent', json_build_object('userid', uUserId, 'event', 'start-transaction-failed', 'reason', 'payment-error', 'message', vMessage)::text);

          PERFORM SendPush(uPayment, vTitle, vMessage, uUserId);
          PERFORM CreateNotice(uUserId, uPayment, vMessage, 'system', 0, jsonb_build_object('title', vTitle, 'body', vMessage));
        END IF;

        PERFORM WriteToEventLog('W', 2000, vCode, format('%s: %s', vTitle, vMessage), uPayment);
      ELSE
        IF e.invoice IS NOT NULL THEN
          IF IsEnabled(e.invoice) THEN
            PERFORM DoTryAction(e.invoice, 'fail');
          END IF;
        END IF;
      END IF;

      PERFORM DoTryAction(uPayment, 'reject'); --> canceled

    ELSIF vStateCode = 'waiting_for_capture' THEN

      PERFORM DoAction(uPayment, 'reject'); --> canceled

    END IF;

  ELSIF p.event = 'refund.succeeded' THEN

    IF GetObjectStateCode(uPayment) = 'succeeded' THEN
      PERFORM AddObjectState(uPayment, GetState(GetClass('yookassa'), 'refunded'));

      IF e.invoice IS NOT NULL THEN
        IF IsDisabled(e.invoice) THEN
          PERFORM DoDelete(e.invoice);
        END IF;
      END IF;
    END IF;

  END IF;

  IF vSession IS NOT NULL THEN
    PERFORM SubstituteUser(session_userid(), vOAuthSecret);
    PERFORM SessionOut(vSession, false);
  END IF;

  RETURN true;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM WriteDiagnostics(vMessage, vContext, uPayment);

  RETURN false;
END
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- api.yookassa_done -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.yookassa_done
 * @param {uuid} pRequest - Request
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.yookassa_done (
  pRequest      uuid
) RETURNS       void
AS $$
DECLARE
  q             record;
  r             record;
  d             record;
  p             record;
  m             record;
  s             record;

  uCard         uuid;
  uAgent        uuid;
  uOrder        uuid;
  uClient       uuid;
  uUserId       uuid;
  uPayment      uuid;
  uInvoice      uuid;

  payload       jsonb;
  jMetadata     jsonb;

  vCode         text;
  vTitle        text;
  vContent      text;
  vStateCode    text;
  vMessage      text;
  vContext      text;
BEGIN
  SELECT agent, command, profile, resource, data INTO q FROM http.request WHERE id = pRequest;
  SELECT status, status_text, content INTO r FROM http.response WHERE id = pRequest;

  SELECT * INTO d FROM jsonb_to_record(q.data) AS x(session text, userid uuid, "payment" uuid, card uuid);

  IF d.session IS NOT NULL THEN
    PERFORM SessionIn(d.session);
  END IF;

  uAgent := GetAgent('yookassa.agent');

  vContent := convert_from(r.content, 'utf8');
  payload := vContent::jsonb;

  IF coalesce(r.status, 0) = 200 THEN

    IF q.command IN ('/payment', '/payment/create', '/payment/capture', '/payment/cancel', '/payment/refund') THEN
      SELECT * INTO p FROM jsonb_to_record(payload) AS x(id uuid, status text, amount jsonb, income_amount jsonb, description text, recipient jsonb, payment_method jsonb, captured_at timestamp, created_at timestamp, expires_at timestamp, confirmation jsonb, test boolean, refunded_amount jsonb, paid boolean, refundable boolean, receipt_registration text, metadata jsonb, cancellation_details jsonb, authorization_details jsonb, transfers jsonb, deal jsonb, merchant_customer_id text);

      uPayment := coalesce((p.metadata->>'payment')::uuid, d."payment");

      IF uPayment IS NOT NULL THEN
        UPDATE db.payment SET payment_id = p.id WHERE id = uPayment AND payment_id IS NULL;

        IF p.status = 'pending' THEN

          IF GetObjectStateCode(uPayment) = 'pending' THEN
            IF p.confirmation IS NOT NULL THEN
              IF p.confirmation->>'type' = 'redirect' THEN
                PERFORM CreateConfirmation(uAgent, uPayment, p.confirmation);
              END IF;
            END IF;
          END IF;

        ELSIF p.status = 'succeeded' THEN

          vStateCode := GetObjectStateCode(uPayment);

          IF vStateCode IN ('pending', 'confirming', 'failed') THEN
            PERFORM CreditingPayment(uPayment);

            IF vStateCode = 'failed' THEN
              PERFORM AddObjectState(uPayment, GetState(GetClass('yookassa'), 'succeeded'));
            ELSE
              PERFORM DoAction(uPayment, 'done'); --> succeeded
            END IF;

            IF q.command = '/payment/refund' THEN
              SELECT "order" INTO uOrder FROM db.payment WHERE id = uPayment;
              IF uOrder IS NOT NULL AND IsDisabled(uOrder) THEN
                PERFORM DoTryAction(uOrder, 'refund');
              END IF;
            END IF;

            SELECT invoice INTO uInvoice FROM db.payment WHERE id = uPayment;

            IF uInvoice IS NOT NULL THEN
              IF IsEnabled(uInvoice) THEN
                BEGIN
                  PERFORM DoDisable(uInvoice);
                  IF NOT p.test THEN
                    PERFORM CP_Kkt(uInvoice);
                  END IF;
                EXCEPTION
                WHEN others THEN
                  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
                  PERFORM WriteDiagnostics(vMessage, vContext);
                END;
              END IF;
            END IF;

          ELSIF vStateCode = 'refunding' THEN
            PERFORM DoAction(uPayment, 'done'); --> refunded

            SELECT "order" INTO uOrder FROM db.payment WHERE id = uPayment;
            IF uOrder IS NOT NULL AND IsDisabled(uOrder) THEN
              PERFORM DoTryAction(uOrder, 'refund');
            END IF;
          END IF;

        ELSIF p.status = 'waiting_for_capture' THEN

          vStateCode := GetObjectStateCode(uPayment);

          IF vStateCode = 'pending' THEN
            IF GetObjectTypeCode(uPayment) = 'validation.yookassa' THEN
              PERFORM DoAction(uPayment, 'cancel'); --> canceling
            ELSE
              PERFORM DoTryAction(uPayment, 'continue'); --> waiting_for_capture

              SELECT metadata INTO jMetadata FROM db.payment WHERE id = uPayment;

              IF jMetadata IS NOT NULL THEN
                SELECT * INTO m FROM jsonb_to_record(jMetadata) AS x(remote_start_transaction jsonb);
                IF m.remote_start_transaction IS NOT NULL THEN
                  SELECT * INTO s FROM jsonb_to_record(m.remote_start_transaction) AS x(connector uuid, preset jsonb);
                  IF s.connector IS NOT NULL THEN
                    BEGIN
                      PERFORM api.remote_start_transaction(s.connector, s.preset);
                    EXCEPTION
                    WHEN others THEN
                      GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
                      PERFORM WriteDiagnostics(vMessage, vContext);
                      PERFORM CheckPaymentReservation(s.connector);
                    END;
                  END IF;
                END IF;
              END IF;
            END IF;
          ELSIF vStateCode = 'failed' THEN
            PERFORM AddObjectState(uPayment, GetState(GetClass('yookassa'), 'waiting_for_capture'));
          END IF;

        ELSIF p.status = 'canceled' THEN

          vStateCode := GetObjectStateCode(uPayment);

          IF vStateCode = 'canceling' THEN

            IF GetObjectTypeCode(uPayment) = 'validation.yookassa' THEN
              SELECT * INTO m FROM jsonb_to_record(p.payment_method) AS x(id text, type text, saved boolean);

              IF m.type = 'bank_card' AND m.saved THEN
                SELECT card INTO uCard FROM db.payment WHERE id = uPayment;

                PERFORM SetCardData(uCard, uAgent, null, m.id, null, p.payment_method);

                IF IsCreated(uCard) THEN
                  UPDATE db.card SET binding = m.id WHERE id = uCard;

                  PERFORM DoEnable(uCard);
                  PERFORM EditCard(uCard, pSequence => 0);
                END IF;
              END IF;
            ELSE
              SELECT invoice INTO uInvoice FROM db.payment WHERE id = uPayment;

              IF uInvoice IS NOT NULL THEN
                IF IsEnabled(uInvoice) THEN
                  PERFORM DoDelete(uInvoice);
                END IF;
              END IF;
            END IF;

            PERFORM DoAction(uPayment, 'done'); --> canceled

          ELSIF vStateCode = 'pending' THEN

            vCode := GetObjectTypeCode(uPayment);

            IF vCode = 'validation.yookassa' THEN
              SELECT card INTO uCard FROM db.payment WHERE id = uPayment;

              PERFORM ClearCardData(uCard, uAgent);

              IF IsCreated(uCard) THEN
                PERFORM DoDisable(uCard);
              END IF;
            ELSIF vCode = 'reserve.yookassa' THEN
              SELECT client INTO uClient FROM db.payment WHERE id = uPayment;

              vTitle := 'Зарядная сессия прервана';
              vMessage := format('Не удалось зарезервировать %s %s для начала зарядной сессии.', p.amount->>'value', p.amount->>'currency');

              uUserId := GetClientUserId(uClient);
              IF uUserId IS NOT NULL THEN
                PERFORM pg_notify('urgent', json_build_object('userid', uUserId, 'event', 'start-transaction-failed', 'reason', 'payment-error', 'message', vMessage)::text);

                PERFORM SendPush(uPayment, vTitle, vMessage, uUserId);
                PERFORM CreateNotice(uUserId, uPayment, vMessage, 'system', 0, jsonb_build_object('title', vTitle, 'body', vMessage));
              END IF;

              PERFORM WriteToEventLog('W', 2000, vCode, format('%s: %s', vTitle, vMessage), uPayment);
            ELSE
              SELECT invoice INTO uInvoice FROM db.payment WHERE id = uPayment;

              IF uInvoice IS NOT NULL THEN
                IF IsEnabled(uInvoice) THEN
                  PERFORM DoTryAction(uInvoice, 'fail');
                END IF;
              END IF;
            END IF;

            PERFORM DoTryAction(uPayment, 'reject'); --> canceled

          ELSIF vStateCode = 'waiting_for_capture' THEN

            PERFORM DoTryAction(uPayment, 'reject'); --> canceled

          ELSE

            PERFORM AddObjectState(uPayment, GetState(GetClass('yookassa'), 'canceled'));

          END IF;
        END IF;
      END IF;
    END IF;

  ELSE

    SELECT * INTO p FROM jsonb_to_record(payload) AS x(id uuid, type text, code text, description text);

    IF q.command = '/payment/create' THEN
      uCard := d.card;
      IF uCard IS NOT NULL THEN
        IF IsCreated(uCard) THEN
          PERFORM EditDocument(uCard, pDescription => p.description);
          PERFORM DoDelete(uCard);
        END IF;
      END IF;
    END IF;

    uPayment := d."payment";

    IF uPayment IS NOT NULL THEN
      IF p.description IS NOT NULL THEN
        PERFORM YK_Error(uPayment, r.status, 'yookassa', p.description);
      ELSE
        PERFORM YK_Error(uPayment, r.status, 'yookassa', coalesce(vContent, r.status_text));
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
-- api.yookassa_fail -----------------------------------------------------------
--------------------------------------------------------------------------------

/**
 * @brief api.yookassa_fail
 * @param {uuid} pRequest - Request
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.yookassa_fail (
  pRequest          uuid
) RETURNS           void
AS $$
DECLARE
  r                 record;
  d                 record;

  uPayment          uuid;
BEGIN
  SELECT method, resource, agent, command, error, data INTO r
    FROM http.request
   WHERE id = pRequest;

  SELECT * INTO d FROM jsonb_to_record(r.data) AS x(session text, userid uuid, payment uuid, card uuid);

  IF d.session IS NOT NULL THEN
    PERFORM SessionIn(d.session);
  END IF;

  uPayment := d.payment;

  IF uPayment IS NOT NULL THEN
    PERFORM YK_Error(uPayment, 500, r.agent, coalesce(r.error, 'Unknown error.'));
	PERFORM DoAction(uPayment, 'fail');
  ELSE
    PERFORM WriteToEventLog('E', 500, r.agent, format('[%s] %s', r.command, coalesce(r.error, 'Unknown error.')));
  END IF;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, public, pg_temp;
