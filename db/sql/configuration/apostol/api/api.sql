--------------------------------------------------------------------------------
-- API -------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.signup ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Register a new client with user account
 * @param {text} pType - Client type code (e.g., 'person.customer')
 * @param {text} pUserName - Username (login)
 * @param {text} pPassword - Password
 * @param {text} pName - Full company name or person's full name
 * @param {text} pPhone - Phone number
 * @param {text} pEmail - Email address
 * @param {text} pDescription - Client description
 * @param {jsonb} pProfile - Additional user account profile data (locale, area, interface, birthday, identity docs, etc.)
 * @out param {uuid} id - Client identifier
 * @out param {uuid} userId - User account identifier
 * @out param {text} uid - Username (login)
 * @out param {text} secret - User secret key (HMAC-SHA512 hash)
 * @return {record}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.signup (
  pType         text,
  pUserName     text,
  pPassword     text,
  pName         text,
  pPhone        text DEFAULT null,
  pEmail        text DEFAULT null,
  pDescription  text DEFAULT null,
  pProfile      jsonb DEFAULT null,
  OUT id        uuid,
  OUT userId    uuid,
  OUT uid       text,
  OUT secret    text
) RETURNS       record
AS $$
DECLARE
  r             record;
  p             record;
  cn            record;

  uClient       uuid;
  uArea         uuid;
  uSaveArea     uuid;
  uUserId       uuid;

  jName         jsonb;

  vOAuthSecret  text;
  vSecret       text;
BEGIN
  pType := coalesce(pType, 'person.customer');
  pUserName := NULLIF(trim(pUserName), '');
  pPhone := TrimPhone(NULLIF(trim(pPhone), ''));
  pEmail := NULLIF(trim(pEmail), '');
  pUserName := coalesce(pUserName, pEmail, pPhone);
  pPassword := NULLIF(pPassword, '');
  pDescription := NULLIF(pDescription, '');
  uSaveArea := current_area();

  SELECT u.id INTO uUserId FROM db.user u WHERE type = 'U' AND username = pUserName;

  IF FOUND THEN
    RAISE EXCEPTION 'ERR-40005: Account "%" is already registered.', pUserName;
  END IF;

  SELECT u.id INTO uUserId FROM db.user u WHERE type = 'U' AND phone = pPhone;

  IF FOUND THEN
    RAISE EXCEPTION 'ERR-40005: Account with phone number "%" is already registered.', pPhone;
  END IF;

  SELECT u.id INTO uUserId FROM db.user u WHERE type = 'U' AND email = pEmail;

  IF FOUND THEN
    RAISE EXCEPTION 'ERR-40005: Account with email "%" is already registered.', pEmail;
  END IF;

  IF pEmail IS NOT NULL AND NOT is_valid_email(pEmail) THEN
    RAISE EXCEPTION 'ERR-40005: Invalid email address: "%".', pEmail;
  END IF;

  jName := BuildClientName(CodeToType(pType, 'client'), pName);

  SELECT * INTO cn FROM jsonb_to_record(jName) AS x(name text, short text, first text, last text, middle text);

  IF NULLIF(cn.name, '') IS NULL THEN
    cn.name := pUserName;
  END IF;

  IF IsUserRole(GetGroup('system'), session_userid()) THEN
    SELECT a.secret INTO vOAuthSecret FROM oauth2.audience a WHERE a.code = session_username();
    IF FOUND THEN
      PERFORM SubstituteUser(GetUser('apibot'), vOAuthSecret);
    END IF;
  END IF;

  FOR r IN SELECT unnest(ARRAY['00000000-0000-4002-a001-000000000001'::uuid, '00000000-0000-4002-a001-000000000000'::uuid]) AS type -- main, default
  LOOP
    SELECT a.id INTO uArea FROM db.area a WHERE a.type = r.type AND a.scope = current_scope();
    EXIT WHEN uArea IS NOT NULL;
  END LOOP;

  PERFORM SetSessionArea(uArea);

  uUserId := CreateUser(pUserName, pPassword, coalesce(NULLIF(trim(cn.short), ''), cn.name), pPhone, pEmail, cn.name, true, false);

  PERFORM AddMemberToGroup(uUserId, GetGroup('guest'));
  PERFORM AddMemberToArea(uUserId, uArea);

  FOR p IN SELECT * FROM jsonb_to_record(pProfile) AS x(locale uuid, locale_code text, area uuid, area_code text, interface uuid, email_verified bool, phone_verified bool, picture text, ticket uuid, code text)
  LOOP
    IF p.ticket IS NOT NULL AND CheckRecoveryTicket(p.ticket, p.code) IS NULL THEN
      RAISE EXCEPTION 'ERR-40000: %', GetErrorMessage();
    END IF;

    p.locale := coalesce(p.locale, GetLocale(p.locale_code));
    p.area := coalesce(p.area, GetArea(p.area_code), uArea, '00000000-0000-4003-a000-000000000002'::uuid);
    p.interface := coalesce(p.interface, '00000000-0000-4004-a000-000000000003'::uuid);
    p.email_verified := coalesce(p.email_verified, false);
    p.phone_verified := coalesce(p.phone_verified, false);

    PERFORM AddMemberToArea(uUserId, p.area);
    PERFORM AddMemberToInterface(uUserId, p.interface);

    IF NOT UpdateProfile(uUserId, current_scope(), cn.first, cn.last, cn.middle, p.locale, p.area, p.interface, p.email_verified, p.phone_verified, p.picture) THEN
      PERFORM CreateProfile(uUserId, current_scope(), cn.first, cn.last, cn.middle, p.locale, p.area, p.interface, p.email_verified, p.phone_verified, p.picture);
    END IF;
  END LOOP;

  SELECT encode(hmac(u.secret::text, GetSecretKey(), 'sha512'), 'hex') INTO vSecret FROM db.user u WHERE u.id = uUserId;

  SELECT * INTO p FROM jsonb_to_record(pProfile) AS x(birthday date, birthplace text, series text, number text, issued text, issueddate date, issuedcode text, inn text, pin text, kpp text, ogrn text, bic text, account text, address text, photo text);

  uClient := CreateClient(null, CodeToType(pType, 'client'), current_company(), uUserId, pUserName, pName, pPhone, pEmail, p.birthday, p.birthplace, p.series, p.number, p.issued, p.issueddate, p.issuedcode, p.inn, p.pin, p.kpp, p.ogrn, p.bic, p.account, p.address, decode(p.photo, 'base64'), pDescription);
  PERFORM DoEnable(uClient);

  PERFORM SetSessionArea(uSaveArea);

  IF vOAuthSecret IS NOT NULL THEN
    PERFORM SubstituteUser(session_userid(), vOAuthSecret);
  END IF;

  id := uClient;
  userId := uUserId;
  uid := pUserName;
  secret := vSecret;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Return current user information (who am I)
 * @field {uuid} id - Client identifier
 * @field {uuid} userid - Virtual user (account) identifier
 * @field {uuid} suid - System user (account) identifier
 * @field {boolean} admin - System administrator flag
 * @field {boolean} guest - Guest login flag
 * @field {json} profile - User profile
 * @field {json} name - Client full name (first, last, middle)
 * @field {json} email - Client email directory
 * @field {json} phone - Client phone directory
 * @field {json} account - Account and balance data
 * @field {json} session - Session info
 * @field {json} locale - Locale settings
 * @field {json} scope - Object visibility scope
 * @field {json} area - Document visibility area
 * @field {json} interface - UI interface settings
 * @since 1.0.0
 */
CREATE OR REPLACE VIEW api.whoami
AS
  SELECT c.id, s.userid, s.suid,
         IsUserRole('00000000-0000-4000-a000-000000000001', s.userid) AS admin,
         IsUserRole('00000000-0000-4000-a000-000000000003', s.userid) AS guest,
         IsUserRole('00000000-0000-4000-a001-100000000001', s.userid) AS employee,
         IsUserRole('00000000-0000-4000-a001-100000000002', s.userid) AS customer,
         json_build_object('id', p.id, 'code', p.code, 'name', pot.label, 'description', pdt.description) AS company,
         json_build_object('id', c.id, 'code', c.code, 'userid', c.userid, 'type', json_build_object('id', t.id, 'code', t.code, 'class', t.class, 'name', tt.name, 'description', tt.description)) AS client,
         json_build_object('name', cn.name, 'short', cn.short, 'first', cn.first, 'last', cn.last, 'middle', cn.middle) AS name,
         c.email, c.phone, c.metadata,
         json_build_object('id', ac.id, 'code', ac.code, 'currency', r.id, 'currency_code', cr.code, 'balance', GetBalance(ac.id)) AS account,
         json_build_object('code', s.code, 'oper_date', s.oper_date, 'created', s.created, 'updated', s.updated, 'agent', s.agent, 'host', s.host) AS session,
         row_to_json(u.*) AS profile,
         row_to_json(l.*) AS locale,
         row_to_json(e.*) AS scope,
         row_to_json(a.*) AS area,
         row_to_json(i.*) AS interface
    FROM db.session s INNER JOIN users u ON u.id = s.userid AND u.scope = current_scope(s.code)
                      INNER JOIN db.locale l ON l.id = s.locale
                      INNER JOIN db.area a ON a.id = s.area
                      INNER JOIN db.scope e ON e.id = a.scope
                      INNER JOIN db.interface i ON i.id = s.interface
                       LEFT JOIN db.company p ON p.id = s.area
                       LEFT JOIN db.object_text pot ON pot.object = p.id AND pot.locale = current_locale()
                       LEFT JOIN db.document_text pdt ON pdt.document = p.id AND pdt.locale = current_locale()
                       LEFT JOIN db.client c ON c.userid = s.userid
                       LEFT JOIN db.object o ON c.document = o.id
                       LEFT JOIN db.type t ON o.type = t.id
                       LEFT JOIN db.type_text tt ON tt.type = t.id AND tt.locale = current_locale()
                       LEFT JOIN db.client_name cn ON cn.client = c.id AND cn.locale = current_locale() AND cn.validfromdate <= oper_date() AND cn.validtodate > oper_date()
                       LEFT JOIN db.currency r ON r.id = GetCurrency(coalesce(RegGetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Currency', s.userid), 'RUB'))
                       LEFT JOIN db.reference cr ON cr.id = r.id
                       LEFT JOIN db.account ac ON ac.code = GenAccountCode(c.id, r.id, '100')
   WHERE s.code = current_session();

--------------------------------------------------------------------------------
-- api.whoami ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Return current user information as a result set
 * @return {SETOF api.whoami} - Current user info row
 * @see api.whoami (view)
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.whoami (
) RETURNS SETOF api.whoami
AS $$
  SELECT * FROM api.whoami
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.garbage_collector -------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * @brief Garbage collector for stale records
 * @param {interval} pOffTime - Age threshold for deletion (default: 1 month)
 * @param {integer} pLimit - Maximum records to delete per table per run (default: 10000)
 * @return {void}
 * @since 1.0.0
 */
CREATE OR REPLACE FUNCTION api.garbage_collector (
  pOffTime  interval DEFAULT '1 month',
  pLimit    integer DEFAULT 10000
) RETURNS   void
AS $$
DECLARE
  r         record;

  vMessage  text;
  vContext  text;
BEGIN
  FOR r IN
    SELECT os.id
      FROM db.job j INNER JOIN db.object_state os ON j.document = os.object
     WHERE os.validtodate < Now() - pOffTime
     LIMIT pLimit
  LOOP
    DELETE FROM db.object_state WHERE id = r.id;
  END LOOP;

  FOR r IN SELECT id FROM db.notification WHERE datetime < Now() - pOffTime LIMIT pLimit
  LOOP
    DELETE FROM db.notification WHERE id = r.id;
  END LOOP;

  FOR r IN SELECT id FROM db.api_log WHERE datetime < Now() - pOffTime LIMIT pLimit
  LOOP
    DELETE FROM db.api_log WHERE id = r.id;
  END LOOP;

  FOR r IN SELECT id FROM db.log WHERE event = 'heartbeat' AND datetime < Now() - pOffTime LIMIT pLimit
  LOOP
    DELETE FROM db.log WHERE id = r.id;
  END LOOP;

  FOR r IN SELECT id FROM db.meter_value WHERE validfromdate < Now() - pOffTime ORDER BY transactionid LIMIT pLimit
  LOOP
    DELETE FROM db.meter_value WHERE id = r.id;
  END LOOP;

  FOR r IN SELECT id FROM db.data_transfer WHERE timestamp < Now() - INTERVAL '1 day' ORDER BY id LIMIT pLimit
  LOOP
    DELETE FROM db.data_transfer WHERE id = r.id;
  END LOOP;
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;
  PERFORM WriteDiagnostics(vMessage, vContext);
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
