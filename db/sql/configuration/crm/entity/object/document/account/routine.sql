--------------------------------------------------------------------------------
-- CreateAccount ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт счёт
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pClient - Клиент
 * @param {uuid} pCategory - Категория
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION CreateAccount (
  pParent       uuid,
  pType         uuid,
  pCurrency     uuid,
  pClient       uuid,
  pCategory     uuid,
  pCode         text,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
DECLARE
  uAccount      uuid;
  uDocument     uuid;

  uClass        uuid;
  uMethod       uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'account' THEN
    PERFORM IncorrectClassType();
  END IF;

  pCurrency := coalesce(pCurrency, DefaultCurrency());

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  pCode := coalesce(pCode, GenAccountCode(pClient, pType, pCurrency));

  PERFORM FROM db.account WHERE currency = pCurrency AND code = pCode;
  IF FOUND THEN
    PERFORM AccountCodeExists(pCode);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  IF pCategory IS NOT NULL THEN
    PERFORM FROM db.category WHERE id = pCategory;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('category', 'id', pCategory);
    END IF;
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.account (id, document, currency, client, category, code)
  VALUES (uDocument, uDocument, pCurrency, pClient, pCategory, pCode)
  RETURNING id INTO uAccount;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uAccount, uMethod);

  RETURN uAccount;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditAccount -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует счёт.
 * @param {uuid} pId - Идентификатор
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Тип
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pClient - Клиент
 * @param {uuid} pCategory - Категория
 * @param {text} pCode - Код
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditAccount (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCurrency     uuid default null,
  pClient       uuid default null,
  pCategory     uuid default null,
  pCode         text default null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uClass        uuid;
  uMethod       uuid;

  -- current
  cCurrency     uuid;
  cClient       uuid;
  cCode         text;
BEGIN
  SELECT currency, client, code INTO cCurrency, cClient, cCode FROM db.account WHERE id = pId;

  pCurrency := coalesce(pCurrency, cCurrency);
  pClient := coalesce(pClient, cClient);
  pCode := coalesce(pCode, cCode);

  IF pCode <> cCode THEN
    PERFORM FROM db.account WHERE currency = pCurrency AND code = pCode;
    IF FOUND THEN
      PERFORM AccountCodeExists(pCode);
    END IF;
  END IF;

  PERFORM FROM db.currency WHERE id = pCurrency;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('currency', 'id', pCurrency);
  END IF;

  PERFORM FROM db.client WHERE id = pClient;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('client', 'id', pClient);
  END IF;

  IF pCategory IS NOT NULL THEN
    PERFORM FROM db.category WHERE id = pCategory;
    IF NOT FOUND THEN
      PERFORM ObjectNotFound('category', 'id', pCategory);
    END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription);

  UPDATE db.account
     SET currency = coalesce(pCurrency, currency),
         client = coalesce(pClient, client),
         category = coalesce(pCategory, category),
         code = pCode
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));

  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccount ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetAccount (
  pCode     text,
  pCurrency uuid
) RETURNS   uuid
AS $$
  SELECT id FROM db.account WHERE currency = pCurrency AND code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountCode --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetAccountCode (
  pAccount  uuid
) RETURNS   text
AS $$
  SELECT code FROM db.account WHERE id = pAccount;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GenAccountCode --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GenAccountCode (
  pClient   uuid,
  pType     uuid DEFAULT null,
  pCurrency uuid DEFAULT null,
  pPrefix   text DEFAULT null
) RETURNS   text
AS $$
BEGIN
  pCurrency := coalesce(pCurrency, DefaultCurrency());
  pType := coalesce(pType, GetType('passive.account'));
  pPrefix := coalesce(pPrefix, lower(GetCurrencyCode(pCurrency)));

  RETURN pPrefix || ':' || encode(digest(format('%s:%s:%s:%s', pPrefix, pClient, pType, pCurrency), 'sha1'), 'hex');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, public, pg_temp;

--------------------------------------------------------------------------------
-- GetClientAccount ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetClientAccount (
  pClient   uuid,
  pType     uuid DEFAULT null,
  pCurrency uuid DEFAULT null,
  pPrefix   text DEFAULT null
) RETURNS   uuid
AS $$
BEGIN
  RETURN GetAccount(GenAccountCode(pClient, pType, pCurrency, pPrefix), pCurrency);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountClient ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetAccountClient (
  pId       uuid
) RETURNS   uuid
AS $$
  SELECT client FROM db.account WHERE id = pId;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetAccountJson --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetAccountJson (
  pClient       uuid
) RETURNS       json
AS $$
DECLARE
  arResult      json[];
  rec           record;
BEGIN
  FOR rec IN
    SELECT * FROM Account WHERE client = pClient
  LOOP
    arResult := array_append(arResult, row_to_json(rec));
  END LOOP;

  RETURN array_to_json(arResult);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetBalanceJson --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetBalanceJsonb (
  pClient       uuid
) RETURNS       jsonb
AS $$
DECLARE
  arResult      jsonb;
  rec           record;
BEGIN
  arResult := jsonb_build_object();

  FOR rec IN
    SELECT CASE
             WHEN SubStr(t.code, 1, 3) = 'gpt' THEN 'token'
             WHEN SubStr(t.code, 1, 3) = 'wrd' THEN 'word'
             WHEN SubStr(t.code, 1, 3) = 'txt' THEN 'text'
             WHEN SubStr(t.code, 1, 3) = 'img' THEN 'image'
             ELSE lower(cr.code)
           END AS type, coalesce(b.amount, 0) AS amount
      FROM db.account t INNER JOIN db.object           o ON o.id = t.document AND o.state_type = '00000000-0000-4000-b001-000000000002'::uuid
                        INNER JOIN db.type             e ON e.id = o.type AND e.code = 'passive.account'
                        INNER JOIN db.currency         c ON c.id = t.currency
                        INNER JOIN db.reference       cr ON cr.id = c.reference
                         LEFT JOIN db.balance          b ON b.account = t.id AND b.type = 1 AND validFromDate <= Now() AND validToDate > Now()
     WHERE t.client = pClient
  LOOP
    arResult := arResult || jsonb_build_object(rec.type, rec.amount);
  END LOOP;

  RETURN arResult;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
