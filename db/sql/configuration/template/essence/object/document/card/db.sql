--------------------------------------------------------------------------------
-- db.card ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.card (
    id			numeric(12) PRIMARY KEY,
    document	numeric(12) NOT NULL,
    client		numeric(12),
    code		varchar(30) NOT NULL,
    name        text,
    expire      date,
    CONSTRAINT fk_card_document FOREIGN KEY (document) REFERENCES db.document(id),
    CONSTRAINT fk_card_client FOREIGN KEY (client) REFERENCES db.client(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.card IS 'Пластиковая карта для зарядной станции.';

COMMENT ON COLUMN db.card.id IS 'Идентификатор';
COMMENT ON COLUMN db.card.document IS 'Ссылка на документ';
COMMENT ON COLUMN db.card.client IS 'Клиент';
COMMENT ON COLUMN db.card.code IS 'Код';
COMMENT ON COLUMN db.card.name IS 'Наименование';
COMMENT ON COLUMN db.card.expire IS 'Дата окончания';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.card (code);

CREATE INDEX ON db.card (document);
CREATE INDEX ON db.card (client);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_card_before_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL OR NEW.id = 0 THEN
    SELECT NEW.DOCUMENT INTO NEW.id;
  END IF;

  RAISE DEBUG '[%] Добавлена карта: %', NEW.Id, NEW.Code;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_card_before_insert
  BEFORE INSERT ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE ft_card_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_card_after_insert()
RETURNS trigger AS $$
DECLARE
  nUserId	numeric;
BEGIN
  IF NEW.client IS NOT NULL THEN
    nUserId := GetClientUserId(NEW.client);
    IF nUserId IS NOT NULL THEN
      UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = nUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, nUserId, B'000', B'100';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_card_after_insert
  AFTER INSERT ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_card_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_card_before_update()
RETURNS trigger AS $$
DECLARE
  nParent	numeric;
  nUserId	numeric;
BEGIN
  IF OLD.client IS NULL AND NEW.client IS NOT NULL THEN
    nUserId := GetClientUserId(NEW.client);
    PERFORM CheckObjectAccess(NEW.document, B'010', nUserId);
    SELECT parent INTO nParent FROM db.object WHERE id = NEW.document;
    IF nParent IS NOT NULL THEN
      PERFORM CheckObjectAccess(nParent, B'010', nUserId);
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_card_before_update
  BEFORE UPDATE ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE ft_card_before_update();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_card_after_update()
RETURNS trigger AS $$
DECLARE
  nUserId	numeric;
BEGIN
  IF coalesce(OLD.client, 0) <> coalesce(NEW.client, 0) THEN
    IF NEW.client IS NOT NULL THEN
      nUserId := GetClientUserId(NEW.client);
      IF nUserId IS NOT NULL THEN
        INSERT INTO db.aou SELECT NEW.document, nUserId, B'000', B'100';
      END IF;
    END IF;

    IF OLD.client IS NOT NULL THEN
      nUserId := GetClientUserId(OLD.client);
      IF nUserId IS NOT NULL THEN
        DELETE FROM db.aou WHERE object = OLD.document AND userid = nUserId;
      END IF;
    END IF;
  END IF;

  RAISE DEBUG '[%] Обнавлёна карта: %', NEW.Id, NEW.Code;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_card_after_update
  AFTER UPDATE ON db.card
  FOR EACH ROW
  EXECUTE PROCEDURE ft_card_after_update();

--------------------------------------------------------------------------------
-- CreateCard ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт новую карту
 * @param {numeric} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {numeric} pType - Тип
 * @param {numeric} pClient - Клиент
 * @param {varchar} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpire - Дата окончания
 * @param {text} pDescription - Описание
 * @return {numeric} - Id карты
 */
CREATE OR REPLACE FUNCTION CreateCard (
  pParent       numeric,
  pType         numeric,
  pClient       numeric,
  pCode         varchar,
  pName         text default null,
  pExpire       date default null,
  pDescription  text default null
) RETURNS       numeric
AS $$
DECLARE
  nId           numeric;
  nCard         numeric;
  nDocument     numeric;

  nClass        numeric;
  nMethod       numeric;
BEGIN
  SELECT class INTO nClass FROM type WHERE id = pType;

  IF nClass IS NULL OR GetClassCode(nClass) <> 'card' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO nId FROM db.card WHERE code = pCode;

  IF found THEN
    PERFORM CardCodeExists(pCode);
  END IF;

  nDocument := CreateDocument(pParent, pType, null, pDescription);

  INSERT INTO db.card (id, document, client, code, name, expire)
  VALUES (nDocument, nDocument, pClient, pCode, pName, pExpire)
  RETURNING id INTO nCard;

  nMethod := GetMethod(nClass, null, GetAction('create'));
  PERFORM ExecuteMethod(nCard, nMethod);

  RETURN nCard;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditCard --------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет основные параметры клиента.
 * @param {numeric} pId - Идентификатор клиента
 * @param {numeric} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {numeric} pType - Тип
 * @param {numeric} pClient - Клиент
 * @param {varchar} pCode - Код
 * @param {text} pName - Наименование
 * @param {date} pExpire - Дата окончания
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditCard (
  pId           numeric,
  pParent       numeric default null,
  pType         numeric default null,
  pClient       numeric default null,
  pCode         varchar default null,
  pName         text default null,
  pExpire       date default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  nId           numeric;
  nClass        numeric;
  nMethod       numeric;

  -- current
  cParent       numeric;
  cType         numeric;
  cCode         varchar;
  cDescription  text;
BEGIN
  SELECT parent, type INTO cParent, cType FROM db.object WHERE id = pId;
  SELECT description INTO cDescription FROM db.document WHERE id = pId;
  SELECT code INTO cCode FROM db.card WHERE id = pId;

  pParent := coalesce(pParent, cParent, 0);
  pType := coalesce(pType, cType);
  pCode := coalesce(pCode, cCode);
  pDescription := coalesce(pDescription, cDescription, '<null>');

  IF pCode <> cCode THEN
    SELECT id INTO nId FROM db.card WHERE code = pCode;
    IF found THEN
      PERFORM CardCodeExists(pCode);
    END IF;
  END IF;

  IF pParent <> coalesce(cParent, 0) THEN
    UPDATE db.object SET parent = CheckNull(pParent) WHERE id = pId;
  END IF;

  IF pType <> cType THEN
    UPDATE db.object SET type = pType WHERE id = pId;
  END IF;

  IF pDescription <> coalesce(cDescription, '<null>') THEN
    UPDATE db.document SET description = CheckNull(pDescription) WHERE id = pId;
  END IF;

  UPDATE db.card
     SET Code = pCode,
         Client = coalesce(pClient, client),
         Name = coalesce(pName, name),
         Expire = coalesce(pExpire, expire)
   WHERE Id = pId;

  nClass := GetObjectClass(pId);
  nMethod := GetMethod(nClass, null, GetAction('edit'));
  PERFORM ExecuteMethod(pId, nMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCard ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetCard (
  pCode		varchar
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT id INTO nId FROM db.card WHERE code = pCode;
  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardCode -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetCardCode (
  pCard		numeric
) RETURNS	varchar
AS $$
DECLARE
  vCode     varchar;
BEGIN
  SELECT code INTO vCode FROM db.card WHERE id = pCard;
  RETURN vCode;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetCardClient ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetCardClient (
  pCard		numeric
) RETURNS	numeric
AS $$
DECLARE
  nClient	numeric;
BEGIN
  SELECT Client INTO nClient FROM db.card WHERE id = pCard;
  RETURN nClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- Card ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Card
AS
  SELECT * FROM db.card;

GRANT SELECT ON Card TO administrator;

--------------------------------------------------------------------------------
-- ObjectCard ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCard (Id, Object, Parent,
  Essence, EssenceCode, EssenceName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Client, Name, Expire,
  Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName
)
AS
  SELECT c.id, d.object, d.parent,
         d.essence, d.essencecode, d.essencename,
         d.class, d.classcode, d.classlabel,
         d.type, d.typecode, d.typename, d.typedescription,
         c.code, c.client, c.name, c.expire,
         d.label, d.description,
         d.statetype, d.statetypecode, d.statetypename,
         d.state, d.statecode, d.statelabel, d.lastupdate,
         d.owner, d.ownercode, d.ownername, d.created,
         d.oper, d.opercode, d.opername, d.operdate,
         d.area, d.areacode, d.areaname
    FROM Card c INNER JOIN ObjectDocument d ON d.id = c.document;

GRANT SELECT ON ObjectCard TO administrator;
