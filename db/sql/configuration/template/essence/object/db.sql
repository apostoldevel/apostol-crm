--------------------------------------------------------------------------------
-- OBJECT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object (
    id			numeric(12) PRIMARY KEY,
    parent		numeric(12),
    type		numeric(12) NOT NULL,
    state		numeric(12),
    suid		numeric(12) NOT NULL,
    owner		numeric(12) NOT NULL,
    oper		numeric(12) NOT NULL,
    label		text,
    pdate		timestamp DEFAULT Now() NOT NULL,
    ldate		timestamp DEFAULT Now() NOT NULL,
    udate		timestamp DEFAULT Now() NOT NULL,
    CONSTRAINT fk_object_parent FOREIGN KEY (parent) REFERENCES db.object(id),
    CONSTRAINT fk_object_type FOREIGN KEY (type) REFERENCES db.type(id),
    CONSTRAINT fk_object_state FOREIGN KEY (state) REFERENCES db.state(id),
    CONSTRAINT fk_object_suid FOREIGN KEY (suid) REFERENCES db.user(id),
    CONSTRAINT fk_object_owner FOREIGN KEY (owner) REFERENCES db.user(id),
    CONSTRAINT fk_object_oper FOREIGN KEY (oper) REFERENCES db.user(id)
);

COMMENT ON TABLE db.object IS 'Список объектов.';

COMMENT ON COLUMN db.object.id IS 'Идентификатор';
COMMENT ON COLUMN db.object.parent IS 'Родитель';
COMMENT ON COLUMN db.object.type IS 'Тип';
COMMENT ON COLUMN db.object.suid IS 'Системный пользователь';
COMMENT ON COLUMN db.object.owner IS 'Владелец (пользователь)';
COMMENT ON COLUMN db.object.oper IS 'Пользователь совершивший последнюю операцию';
COMMENT ON COLUMN db.object.label IS 'Метка';
COMMENT ON COLUMN db.object.pdate IS 'Физическая дата';
COMMENT ON COLUMN db.object.ldate IS 'Логическая дата';
COMMENT ON COLUMN db.object.udate IS 'Дата последнего изменения';

CREATE INDEX ON db.object (parent);
CREATE INDEX ON db.object (type);

CREATE INDEX ON db.object (suid);
CREATE INDEX ON db.object (owner);
CREATE INDEX ON db.object (oper);

CREATE INDEX ON db.object (label);
CREATE INDEX ON db.object (label text_pattern_ops);

CREATE INDEX ON db.object (pdate);
CREATE INDEX ON db.object (ldate);
CREATE INDEX ON db.object (udate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_object_before_insert()
RETURNS trigger AS $$
DECLARE
  nClass	numeric;
  bAbstract	boolean;
BEGIN
  IF lower(session_user) = 'kernel' THEN
    PERFORM AccessDeniedForUser(session_user);
  END IF;

  SELECT class INTO nClass FROM db.type WHERE id = NEW.TYPE;
  SELECT abstract INTO bAbstract FROM db.class_tree WHERE id = nClass;

  IF bAbstract THEN
    PERFORM AbstractError();
  END IF;

  IF NEW.ID IS NULL OR NEW.ID = 0 THEN
    SELECT NEXTVAL('SEQUENCE_ID') INTO NEW.ID;
  END IF;

  NEW.SUID := session_userid();
  NEW.OWNER := current_userid();
  NEW.OPER := current_userid();

  NEW.PDATE := now();
  NEW.LDATE := now();
  NEW.UDATE := now();

  RAISE DEBUG 'Создан объект Id: %', NEW.ID;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_object_before_insert
  BEFORE INSERT ON db.object
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_object_before_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_object_after_insert()
RETURNS trigger AS $$
BEGIN
  INSERT INTO db.aom SELECT NEW.ID;
  INSERT INTO db.aou SELECT NEW.ID, 1001, B'000', B'111';
  INSERT INTO db.aou SELECT NEW.ID, NEW.OWNER, B'000', B'111';

  IF NEW.OWNER <> NEW.SUID THEN
    IF NOT IsUserRole(1001, NEW.SUID) THEN
      INSERT INTO db.aou SELECT NEW.ID, NEW.SUID, B'000', B'110';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_object_after_insert
  AFTER INSERT ON db.object
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_object_after_insert();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_object_before_update()
RETURNS trigger AS $$
DECLARE
  nStateType	numeric;
  nOldEssence	numeric;
  nNewEssence	numeric;
  nOldClass     numeric;
  nNewClass     numeric;
BEGIN
  IF lower(session_user) = 'kernel' THEN
    SELECT AccessDeniedForUser(session_user);
  END IF;

  IF OLD.SUID <> NEW.SUID THEN
    PERFORM AccessDenied();
  END IF;

  IF NOT CheckObjectAccess(NEW.ID, B'010') THEN
    PERFORM AccessDenied();
  END IF;

  IF OLD.TYPE <> NEW.TYPE THEN
    SELECT class INTO nOldClass FROM db.type WHERE id = OLD.TYPE;
    SELECT class INTO nNewClass FROM db.type WHERE id = NEW.TYPE;

    SELECT essence INTO nOldEssence FROM db.class_tree WHERE id = nOldClass;
    SELECT essence INTO nNewEssence FROM db.class_tree WHERE id = nNewClass;

    IF nOldEssence <> nNewEssence THEN
      PERFORM IncorrectEssence();
    END IF;
  END IF;

  IF nOldClass <> nNewClass THEN

    SELECT type INTO nStateType FROM db.state WHERE id = OLD.STATE;
    NEW.STATE := GetState(nNewClass, nStateType);

    IF coalesce(OLD.STATE <> NEW.STATE, false) THEN
      UPDATE db.object_state SET state = NEW.STATE
       WHERE object = OLD.ID
         AND state = OLD.STATE;
    END IF;
  END IF;

  IF OLD.owner <> NEW.owner THEN
    DELETE FROM db.aou WHERE object = NEW.id AND userid = OLD.owner AND mask = B'111';
    INSERT INTO db.aou SELECT NEW.id, NEW.owner, B'000', B'111';
  END IF;

  NEW.OPER := current_userid();

  NEW.LDATE := now();
  NEW.UDATE := now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_object_before_update
  BEFORE UPDATE ON db.object
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_object_before_update();

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_object_before_delete()
RETURNS trigger AS $$
BEGIN
  IF lower(session_user) = 'kernel' THEN
    SELECT AccessDeniedForUser(session_user);
  END IF;

  IF NOT CheckObjectAccess(OLD.ID, B'001') THEN
    PERFORM AccessDenied();
  END IF;

  DELETE FROM db.aou WHERE object = OLD.ID;
  DELETE FROM db.aom WHERE object = OLD.ID;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_object_before_delete
  BEFORE DELETE ON db.object
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_object_before_delete();

--------------------------------------------------------------------------------
-- TABLE db.aom ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.aom (
    object		NUMERIC(12) NOT NULL,
    mask		BIT(9) DEFAULT B'111100000' NOT NULL,
    CONSTRAINT fk_aom_object FOREIGN KEY (object) REFERENCES db.object(id)
);

COMMENT ON TABLE db.aom IS 'Маска доступа к объекту.';

COMMENT ON COLUMN db.aom.object IS 'Объект';
COMMENT ON COLUMN db.aom.mask IS 'Маска доступа. Девять бит (a:{u:sud}{g:sud}{o:sud}), по три бита на действие s - select, u - update, d - delete, для: a - all (все) = u - user (владелец) g - group (группа) o - other (остальные)';

CREATE UNIQUE INDEX ON db.aom (object);

--------------------------------------------------------------------------------
-- TABLE db.aou ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.aou (
    object		numeric(12) NOT NULL,
    userid		numeric(12) NOT NULL,
    deny		bit(3) NOT NULL,
    allow		bit(3) NOT NULL,
    mask		bit(3) DEFAULT B'000' NOT NULL,
    CONSTRAINT fk_aou_object FOREIGN KEY (object) REFERENCES db.object(id),
    CONSTRAINT fk_aou_userid FOREIGN KEY (userid) REFERENCES db.user(id)
);

COMMENT ON TABLE db.aou IS 'Доступ пользователя и групп пользователей к объекту.';

COMMENT ON COLUMN db.aou.object IS 'Объект';
COMMENT ON COLUMN db.aou.userid IS 'Пользователь';
COMMENT ON COLUMN db.aou.deny IS 'Запрещающие биты: {s - select, u - update, d - delete}';
COMMENT ON COLUMN db.aou.allow IS 'Разрешающие биты: {s - select, u - update, d - delete}';
COMMENT ON COLUMN db.aou.mask IS 'Маска доступа: {s - select, u - update, d - delete}';

CREATE UNIQUE INDEX ON db.aou (object, userid);

CREATE INDEX ON db.aou (object);
CREATE INDEX ON db.aou (userid);

CREATE OR REPLACE FUNCTION ft_aou_before()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    NEW.mask = NEW.allow & ~NEW.deny;
    RETURN NEW;
  ELSIF (TG_OP = 'UPDATE') THEN
    NEW.mask = NEW.allow & ~NEW.deny;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_aou_before
  BEFORE INSERT OR UPDATE ON db.aou
  FOR EACH ROW
  EXECUTE PROCEDURE ft_aou_before();

--------------------------------------------------------------------------------
-- FUNCTION aou ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION aou (
  pUserId       numeric,
  OUT object    numeric,
  OUT deny      bit,
  OUT allow     bit,
  OUT mask      bit
) RETURNS       SETOF record
AS $$
  WITH member_group AS (
      SELECT pUserId AS userid UNION ALL SELECT userid FROM db.member_group WHERE member = pUserId
  )
  SELECT a.object, bit_or(a.deny), bit_or(a.allow), bit_or(a.mask)
    FROM db.aou a INNER JOIN member_group m ON a.userid = m.userid
   GROUP BY a.object;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION aou ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION aou (
  pUserId       numeric,
  pObject       numeric,
  OUT object    numeric,
  OUT deny      bit,
  OUT allow     bit,
  OUT mask      bit
) RETURNS       SETOF record
AS $$
  WITH member_group AS (
      SELECT pUserId AS userid UNION ALL SELECT userid FROM db.member_group WHERE member = pUserId
  )
  SELECT a.object, bit_or(a.deny), bit_or(a.allow), bit_or(a.mask)
    FROM db.aou a INNER JOIN member_group m ON a.userid = m.userid
     AND a.object = pObject
   GROUP BY a.object
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- chmodo ----------------------------------------------------------------------
--------------------------------------------------------------------------------
/*
 * Устанавливает битовую маску доступа для объектов и пользователя.
 * @param {numeric} pObject - Идентификатор объекта
 * @param {bit} pMask - Маска доступа. Шесть бит (d:{sud}a:{sud}) где: d - запрещающие биты; a - разрешающие биты: {s - select, u - update, d - delete}
 * @param {numeric} pUserId - Идентификатор пользователя/группы
 * @param {char} pMarker - Маркер
 * @return {void}
*/
CREATE OR REPLACE FUNCTION chmodo (
  pObject	numeric,
  pMask		bit,
  pUserId	numeric DEFAULT current_userid()
) RETURNS	void
AS $$
DECLARE
  bDeny      bit;
  bAllow     bit;
BEGIN
  IF session_user <> 'kernel' THEN
    IF NOT IsUserRole(1001) THEN
      PERFORM AccessDenied();
    END IF;
  END IF;

  IF pMask IS NOT NULL THEN
    bDeny := NULLIF(SubString(pMask FROM 1 FOR 3), B'000');
    bAllow := NULLIF(SubString(pMask FROM 4 FOR 3), B'000');

    UPDATE db.aou SET deny = bDeny, allow = bAllow WHERE object = pObject AND userid = pUserId;
    IF NOT FOUND THEN
      INSERT INTO db.aou SELECT pObject, pUserId, bDeny, bAllow;
    END IF;
  ELSE
    DELETE FROM db.aou WHERE object = pObject AND userid = pUserId;
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectMask ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectMask (
  pObject	numeric,
  pUserId	numeric DEFAULT current_userid()
) RETURNS	bit
AS $$
  SELECT CASE
         WHEN pUserId = o.owner THEN SubString(mask FROM 1 FOR 3)
         WHEN EXISTS (SELECT id FROM db.user WHERE id = pUserId AND type = 'G') THEN SubString(mask FROM 4 FOR 3)
         ELSE SubString(mask FROM 7 FOR 3)
         END
    FROM db.aom a INNER JOIN db.object o ON o.id = a.object
   WHERE object = pObject
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectAccessMask ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectAccessMask (
  pObject	numeric,
  pUserId	numeric DEFAULT current_userid()
) RETURNS	bit
AS $$
  SELECT mask FROM aou(pUserId, pObject)
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CheckObjectAccess -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CheckObjectAccess (
  pObject	numeric,
  pMask		bit,
  pUserId	numeric DEFAULT current_userid()
) RETURNS	boolean
AS $$
BEGIN
  RETURN coalesce(coalesce(GetObjectAccessMask(pObject, pUserId), GetObjectMask(pObject, pUserId)) & pMask = pMask, false);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DecodeObjectAccess ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DecodeObjectAccess (
  pObject	numeric,
  pUserId	numeric DEFAULT current_userid(),
  OUT s		boolean,
  OUT u		boolean,
  OUT d		boolean
) RETURNS 	record
AS $$
DECLARE
  bMask		bit(3);
BEGIN
  bMask := coalesce(GetObjectAccessMask(pObject, pUserId), GetObjectMask(pObject, pUserId));

  s := bMask & B'100' = B'100';
  u := bMask & B'010' = B'010';
  d := bMask & B'001' = B'001';
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- VIEW ObjectMembers ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectMembers
AS
  SELECT object, userid, deny::int, allow::int, mask::int, u.type, username, name, description
    FROM db.aou a INNER JOIN db.user u ON u.id = a.userid;

GRANT SELECT ON ObjectMembers TO administrator;

--------------------------------------------------------------------------------
-- GetObjectMembers ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectMembers (
  pObject	numeric
) RETURNS 	SETOF ObjectMembers
AS $$
  SELECT * FROM ObjectMembers WHERE object = pObject;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- VIEW Object -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Object (Id, Parent,
  Essence, EssenceCode, EssenceName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Label,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate
) AS
WITH access AS (
  WITH member_group AS (
      SELECT current_userid() AS userid UNION ALL SELECT userid FROM db.member_group WHERE member = current_userid()
  )
  SELECT a.object
    FROM db.aou a INNER JOIN member_group m ON a.userid = m.userid
   GROUP BY a.object
  HAVING bit_or(a.mask) & B'100' = B'100'
)
  SELECT o.id, o.parent,
         e.id, e.code, e.name,
         c.id, c.code, c.label,
         t.id, t.code, t.name, t.description,
         o.label,
         y.id, y.code, y.name,
         o.state, s.code, s.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate
    FROM db.object o INNER JOIN access a        ON o.id = a.object
                     INNER JOIN db.type t       ON t.id = o.type
                     INNER JOIN db.class_tree c ON c.id = t.class
                     INNER JOIN db.essence e    ON e.id = c.essence
                     INNER JOIN db.state s      ON s.id = o.state
                     INNER JOIN db.state_type y ON y.id = s.type
                     INNER JOIN db.user w       ON w.id = o.owner AND w.type = 'U'
                     INNER JOIN db.user u       ON u.id = o.oper AND u.type = 'U';

GRANT SELECT ON Object TO administrator;

--------------------------------------------------------------------------------
-- CreateObject ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateObject (
  pParent	numeric,
  pType     numeric,
  pLabel	text DEFAULT null
) RETURNS 	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  INSERT INTO db.object (parent, type, label)
  VALUES (pParent, pType, pLabel)
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SetObjectParent -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SetObjectParent (
  nObject	numeric,
  pParent	numeric
) RETURNS	void
AS $$
BEGIN
  UPDATE db.object SET parent = pParent WHERE id = nObject;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectParent -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectParent (
  nObject	numeric
) RETURNS	numeric
AS $$
DECLARE
  nParent	numeric;
BEGIN
  SELECT parent INTO nParent FROM db.object WHERE id = nObject;
  RETURN nParent;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectLabel -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectLabel (
  pObject	numeric
) RETURNS	text
AS $$
DECLARE
  vLabel	text;
BEGIN
  SELECT label INTO vLabel FROM db.object WHERE id = pObject;

  RETURN vLabel;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectClass -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectClass (
  pId		numeric
) RETURNS	numeric
AS $$
DECLARE
  nClass	numeric;
BEGIN
  SELECT class INTO nClass FROM db.type WHERE id = (
    SELECT type FROM db.object WHERE id = pId
  );

  RETURN nClass;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectType ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectType (
  pId		numeric
) RETURNS	numeric
AS $$
DECLARE
  nType         numeric;
BEGIN
  SELECT type INTO nType FROM db.object WHERE id = pId;

  RETURN nType;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectState -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectState (
  pId		numeric
) RETURNS	numeric
AS $$
DECLARE
  nState	numeric;
BEGIN
  SELECT state INTO nState FROM db.object WHERE id = pId;

  RETURN nState;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectOwner -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectOwner (
  pId		numeric
) RETURNS 	numeric
AS $$
DECLARE
  nOwner	numeric;
BEGIN
  SELECT owner INTO nOwner FROM db.object WHERE id = pId;

  RETURN nOwner;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectOper ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectOper (
  pId		numeric
) RETURNS 	numeric
AS $$
DECLARE
  nOper	numeric;
BEGIN
  SELECT oper INTO nOper FROM db.object WHERE id = pId;

  RETURN nOper;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- OBJECT_STATE ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_state (
    id			    numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    object		    numeric(12) NOT NULL,
    state		    numeric(12) NOT NULL,
    validFromDate	timestamp DEFAULT Now() NOT NULL,
    validToDate		timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_object_state_object FOREIGN KEY (object) REFERENCES db.object(id),
    CONSTRAINT fk_object_state_state FOREIGN KEY (state) REFERENCES db.state(id)
);

COMMENT ON TABLE db.object_state IS 'Состояние объекта.';

COMMENT ON COLUMN db.object_state.id IS 'Идентификатор';
COMMENT ON COLUMN db.object_state.object IS 'Объект';
COMMENT ON COLUMN db.object_state.state IS 'Ссылка на состояние объекта';
COMMENT ON COLUMN db.object_state.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.object_state.validToDate IS 'Дата окончания периода действия';

CREATE INDEX ON db.object_state (object);
CREATE INDEX ON db.object_state (state);
CREATE INDEX ON db.object_state (object, validFromDate, validToDate);

CREATE UNIQUE INDEX ON db.object_state (object, state, validFromDate, validToDate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_object_state_change()
RETURNS TRIGGER AS
$$
BEGIN
  IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
    IF NEW.VALIDFROMDATE IS NULL THEN
      NEW.VALIDFROMDATE := now();
    END IF;

    IF NEW.VALIDFROMDATE > NEW.VALIDTODATE THEN
      RAISE EXCEPTION 'ERR-80000: Дата начала периода действия не должна превышать дату окончания периода действия.';
    END IF;

    RETURN NEW;
  ELSE
    IF OLD.VALIDTODATE = MAXDATE() THEN
      UPDATE db.object SET state = NULL WHERE id = OLD.OBJECT;
    END IF;

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_object_state_change
  AFTER INSERT OR UPDATE OR DELETE ON db.object_state
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_object_state_change();

--------------------------------------------------------------------------------
-- VIEW ObjectState ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectState (Id, Object, Class,
  State, StateTypeCode, StateTypeName, StateCode, StateLabel,
  ValidFromDate, validToDate
)
AS
  SELECT o.id, o.object, s.class, o.state, s.typecode, s.typename, s.code, s.label,
         o.validFromDate, o.validToDate
    FROM db.object_state o INNER JOIN State s ON s.id = o.state;

GRANT SELECT ON ObjectState TO administrator;

--------------------------------------------------------------------------------
-- FUNCTION AddObjectState -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddObjectState (
  pObject       numeric,
  pState        numeric,
  pDateFrom     timestamp DEFAULT oper_date()
) RETURNS       numeric
AS $$
DECLARE
  nId           numeric;

  dtDateFrom    timestamp;
  dtDateTo      timestamp;
BEGIN
  -- получим дату значения в текущем диапозоне дат
  SELECT max(validFromDate), max(validToDate) INTO dtDateFrom, dtDateTo
    FROM db.object_state
   WHERE object = pObject
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF dtDateFrom = pDateFrom THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.object_state SET State = pState
     WHERE object = pObject
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.object_state SET validToDate = pDateFrom
     WHERE object = pObject
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.object_state (object, state, validFromDate, validToDate)
    VALUES (pObject, pState, pDateFrom, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO nId;
  END IF;

  UPDATE db.object SET state = pState WHERE id = pObject;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectState -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectState (
  pObject	numeric,
  pDate		timestamp
) RETURNS	numeric
AS $$
DECLARE
  nState	numeric;
BEGIN
  SELECT state INTO nState
    FROM db.object_state
   WHERE object = pObject
     AND validFromDate <= pDate
     AND validToDate > pDate;

  RETURN nState;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectStateCode -------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectStateCode (
  pObject	numeric,
  pDate		timestamp DEFAULT oper_date()
) RETURNS 	varchar
AS $$
DECLARE
  nState	numeric;
  vCode		varchar;
BEGIN
  vCode := null;

  nState := GetObjectState(pObject, pDate);
  IF nState IS NOT NULL THEN
    SELECT code INTO vCode FROM db.state WHERE id = nState;
  END IF;

  RETURN vCode;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectStateType -------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectStateType (
  pObject	numeric,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	numeric
AS $$
DECLARE
  nState	numeric;
BEGIN
  SELECT state INTO nState
    FROM db.object_state
   WHERE object = pObject
     AND validFromDate <= pDate
     AND validToDate > pDate;

  RETURN GetStateTypeByState(nState);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectStateTypeCode ---------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectStateTypeCode (
  pObject	numeric,
  pDate		timestamp DEFAULT oper_date()
) RETURNS 	varchar
AS $$
DECLARE
  nState	numeric;
BEGIN
  SELECT state INTO nState
    FROM db.object_state
   WHERE object = pObject
     AND validFromDate <= pDate
     AND validToDate > pDate;

  RETURN GetStateTypeCodeByState(nState);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetNewState --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetNewState (
  pMethod	numeric
) RETURNS 	numeric
AS $$
DECLARE
  nNewState	numeric;
BEGIN
  SELECT newstate INTO nNewState FROM db.transition WHERE method = pMethod;

  RETURN nNewState;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- PROCEDURE ChangeObjectState -------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ChangeObjectState (
  pObject	numeric DEFAULT context_object(),
  pMethod	numeric DEFAULT context_method()
) RETURNS 	void
AS $$
DECLARE
  nNewState	numeric;
BEGIN
  nNewState := GetNewState(pMethod);
  IF nNewState IS NOT NULL THEN
    PERFORM AddObjectState(pObject, nNewState);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectMethod ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectMethod (
  pObject	numeric,
  pAction	numeric
) RETURNS	numeric
AS $$
DECLARE
  nType     numeric;
  nClass	numeric;
  nState	numeric;
  nMethod	numeric;
BEGIN
  SELECT type, state INTO nType, nState FROM db.object WHERE id = pObject;
  SELECT class INTO nClass FROM db.type WHERE id = nType;

  nMethod := GetMethod(nClass, nState, pAction);

  RETURN nMethod;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- PROCEDURE ExecuteAction -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ExecuteAction (
  pClass	numeric DEFAULT context_class(),
  pAction	numeric DEFAULT context_action()
) RETURNS	void
AS $$
DECLARE
  nClass	numeric;
  Rec		record;
BEGIN
  FOR Rec IN
    SELECT typecode, text
      FROM Event
     WHERE class = pClass
       AND action = pAction
       AND enabled
     ORDER BY sequence
  LOOP
    IF Rec.typecode = 'parent' THEN
      SELECT parent INTO nClass FROM db.class_tree WHERE id = pClass;
      IF nClass IS NOT NULL THEN
        PERFORM ExecuteAction(nClass, pAction);
      END IF;
    ELSIF Rec.typecode = 'event' THEN
      EXECUTE 'SELECT ' || Rec.Text;
    ELSIF Rec.typecode = 'plpgsql' THEN
      EXECUTE Rec.Text;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- PROCEDURE ExecuteMethod -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ExecuteMethod (
  pObject       numeric,
  pMethod       numeric,
  pForm         jsonb DEFAULT null
) RETURNS       void
AS $$
DECLARE
  nSaveObject	numeric;
  nSaveClass	numeric;
  nSaveMethod	numeric;
  nSaveAction	numeric;
  pSaveForm     jsonb;

  nClass        numeric;
  nAction       numeric;
BEGIN
  nSaveObject := context_object();
  nSaveClass  := context_class();
  nSaveMethod := context_method();
  nSaveAction := context_action();
  pSaveForm   := context_form();

  nClass := GetObjectClass(pObject);

  SELECT action INTO nAction FROM db.method WHERE id = pMethod;

  PERFORM InitContext(pObject, nClass, pMethod, nAction);
  PERFORM InitForm(pForm);

  PERFORM ExecuteAction(nClass, nAction);

  PERFORM InitForm(pSaveForm);
  PERFORM InitContext(nSaveObject, nSaveClass, nSaveMethod, nSaveAction);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- PROCEDURE ExecuteMethodForAllChild ------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ExecuteMethodForAllChild (
  pObject	numeric DEFAULT context_object(),
  pClass	numeric DEFAULT context_class(),
  pMethod	numeric DEFAULT context_method(),
  pAction	numeric DEFAULT context_action(),
  pForm		jsonb DEFAULT context_form()
) RETURNS	void
AS $$
DECLARE
  nMethod	numeric;
  rec		RECORD;
BEGIN
  FOR rec IN
    SELECT o.id, t.class, o.state FROM db.object o INNER JOIN db.type t ON o.type = t.id
     WHERE o.parent = pObject AND t.class = pClass
  LOOP
    nMethod := GetMethod(rec.class, rec.state, pAction);
    IF nMethod IS NOT NULL THEN
      PERFORM ExecuteMethod(rec.id, nMethod, pForm);
    END IF;
  END LOOP;

  PERFORM InitContext(pObject, pClass, pMethod, pAction);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- PROCEDURE ExecuteObjectAction -----------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ExecuteObjectAction (
  pObject	numeric,
  pAction	numeric,
  pForm		jsonb DEFAULT null
) RETURNS 	void
AS $$
DECLARE
  nMethod	numeric;
BEGIN
  nMethod := GetObjectMethod(pObject, pAction);
  IF nMethod IS NOT NULL THEN
    PERFORM ExecuteMethod(pObject, nMethod, pForm);
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- db.object_group -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_group (
    id          numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    owner       numeric(12) NOT NULL,
    code        varchar(30) NOT NULL,
    name        varchar(50) NOT NULL,
    description text,
    CONSTRAINT fk_object_group_owner FOREIGN KEY (owner) REFERENCES db.user(id)
);

COMMENT ON TABLE db.object_group IS 'Группа объектов.';

COMMENT ON COLUMN db.object_group.id IS 'Идентификатор';
COMMENT ON COLUMN db.object_group.owner IS 'Владелец';
COMMENT ON COLUMN db.object_group.code IS 'Код';
COMMENT ON COLUMN db.object_group.name IS 'Наименование';
COMMENT ON COLUMN db.object_group.description IS 'Описание';

CREATE INDEX ON db.object_group (owner);

CREATE UNIQUE INDEX ON db.object_group (code);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_object_group_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.OWNER IS NULL THEN
    NEW.OWNER := current_userid();
  END IF;

  IF NEW.CODE IS NULL THEN
    NEW.CODE := 'G:' || TRIM(TO_CHAR(NEW.ID, '999999999999'));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_object_group
  BEFORE INSERT ON db.object_group
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_object_group_insert();

--------------------------------------------------------------------------------
-- CreateObjectGroup -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateObjectGroup (
  pCode		varchar,
  pName		varchar,
  pDescription	varchar
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  INSERT INTO db.object_group (code, name, description)
  VALUES (pCode, pName, pDescription)
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditObjectGroup -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditObjectGroup (
  pId		    numeric,
  pCode		    varchar,
  pName		    varchar,
  pDescription	varchar
) RETURNS	    void
AS $$
BEGIN
  UPDATE db.object_group
     SET code = pCode,
         name = pName,
         description = pDescription
   WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectGroup --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectGroup (
  pCode		varchar
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT id INTO strict nId FROM db.object_group WHERE code = pCode;

  RETURN nId;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN null;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ObjectGroup -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectGroup (Id, Code, Name, Description)
AS
  SELECT id, code, name, description
    FROM db.object_group
   WHERE owner = coalesce(current_userid(), 0);

GRANT SELECT ON ObjectGroup TO administrator;

--------------------------------------------------------------------------------
-- db.object_group_member ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_group_member (
    id          numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    gid         numeric(12) NOT NULL,
    object      numeric(12) NOT NULL,
    CONSTRAINT fk_object_group_member_gid FOREIGN KEY (gid) REFERENCES db.object_group(id),
    CONSTRAINT fk_object_group_member_object FOREIGN KEY (object) REFERENCES db.object(id)
);

COMMENT ON TABLE db.object_group_member IS 'Члены группы объектов.';

COMMENT ON COLUMN db.object_group_member.id IS 'Идентификатор';
COMMENT ON COLUMN db.object_group_member.gid IS 'Группа';
COMMENT ON COLUMN db.object_group_member.object IS 'Объект';

CREATE INDEX ON db.object_group_member (gid);
CREATE INDEX ON db.object_group_member (object);

--------------------------------------------------------------------------------
-- AddObjectToGroup ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddObjectToGroup (
  pGroup	numeric,
  pObject	numeric
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT id INTO nId FROM db.object_group_member WHERE gid = pGroup AND object = pObject;
  IF NOT found THEN
    INSERT INTO db.object_group_member (gid, object) 
    VALUES (pGroup, pObject)
    RETURNING id INTO nId;
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteObjectOfGroup ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DeleteObjectOfGroup (
  pGroup	numeric,
  pObject	numeric
) RETURNS	void
AS $$
DECLARE
  nCount	integer;
BEGIN
  DELETE FROM db.object_group_member
   WHERE gid = pGroup
     AND object = pObject;

  SELECT count(object) INTO nCount 
    FROM db.object_group_member
   WHERE gid = pGroup;

  IF nCount = 0 THEN
    DELETE FROM db.object_group WHERE id = pGroup;
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ObjectGroupMember -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectGroupMember (Id, GId, Object, Code, Name, Description)
AS
  SELECT m.id, m.gid, m.object, g.code, g.name, g.description
    FROM db.object_group_member m INNER JOIN ObjectGroup g ON g.id = m.gid;

GRANT SELECT ON ObjectGroupMember TO administrator;

--------------------------------------------------------------------------------
-- db.object_link --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_link (
    Id			    numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    Object		    numeric(12) NOT NULL,
    Type		    numeric(12) NOT NULL,
    Linked		    numeric(12),
    validFromDate	timestamp DEFAULT Now() NOT NULL,
    validToDate		timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_object_link_object FOREIGN KEY (object) REFERENCES db.object(id),
    CONSTRAINT fk_object_link_type FOREIGN KEY (type) REFERENCES db.type(id),
    CONSTRAINT fk_object_link_linked FOREIGN KEY (linked) REFERENCES db.object(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.object_link IS 'Связанные с объектом объекты.';

COMMENT ON COLUMN db.object_link.object IS 'Идентификатор объекта';
COMMENT ON COLUMN db.object_link.type IS 'Идентификатор типа связанного объекта';
COMMENT ON COLUMN db.object_link.linked IS 'Идентификатор связанного объекта';
COMMENT ON COLUMN db.object_link.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.object_link.validToDate IS 'Дата окончания периода действия';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.object_link (object, type, validFromDate, validToDate);

CREATE INDEX ON db.object_link (object);
CREATE INDEX ON db.object_link (type);
CREATE INDEX ON db.object_link (linked);

--------------------------------------------------------------------------------
-- FUNCTION SetObjectLink ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Устанавливает связь с объектом.
 * @param {numeric} pObject - Идентификатор объекта
 * @param {numeric} pLinked - Идентификатор связанного объекта
 * @param {timestamp} pDateFrom - Дата начала периода
 * @return {void}
 */
CREATE OR REPLACE FUNCTION SetObjectLink (
  pObject	    numeric,
  pLinked	    numeric,
  pDateFrom	    timestamp DEFAULT oper_date()
) RETURNS 	    numeric
AS $$
DECLARE
  nId		    numeric;
  nType		    numeric;

  dtDateFrom    timestamp;
  dtDateTo 	    timestamp;
BEGIN
  nId := null;

  SELECT type INTO nType FROM db.object WHERE id = pLinked;

  -- получим дату значения в текущем диапозоне дат
  SELECT max(validFromDate), max(validToDate) INTO dtDateFrom, dtDateTo
    FROM db.object_link
   WHERE Object = pObject
     AND Type = nType
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF dtDateFrom = pDateFrom THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.object_link SET linked = pLinked
     WHERE Object = pObject
       AND Type = nType
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.object_link SET validToDate = pDateFrom
     WHERE Object = pObject
       AND Type = nType
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.object_link (object, type, linked, validFromDate, validToDate)
    VALUES (pObject, nType, pLinked, pDateFrom, coalesce(dtDateTo, MAXDATE()))
    RETURNING id INTO nId;
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetObjectLink ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает связанный с объектом объект.
 * @param {numeric} pObject - Идентификатор объекта
 * @param {numeric} pType - Идентификатор типа связанного объекта
 * @param {timestamp} pDate - Дата
 * @return {text}
 */
CREATE OR REPLACE FUNCTION GetObjectLink (
  pObject	numeric,
  pType	    numeric,
  pDate		timestamp DEFAULT oper_date()
) RETURNS	text
AS $$
DECLARE
  nLinked		numeric;
BEGIN
  SELECT Linked INTO nLinked
    FROM db.object_link
   WHERE Object = pObject
     AND Type = pType
     AND validFromDate <= pDate
     AND validToDate > pDate;

  RETURN nLinked;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- db.object_file --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_file (
    id			numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    object		numeric(12) NOT NULL,
    load_date	timestamp DEFAULT Now() NOT NULL,
    file_hash	text NOT NULL,
    file_name	text NOT NULL,
    file_path	text DEFAULT NULL,
    file_size	numeric DEFAULT 0,
    file_date	timestamp DEFAULT NULL,
    file_body	bytea DEFAULT NULL,
    CONSTRAINT fk_object_file_object FOREIGN KEY (object) REFERENCES db.object(id)
);

COMMENT ON TABLE db.object_file IS 'Файлы объекта.';

COMMENT ON COLUMN db.object_file.object IS 'Объект';
COMMENT ON COLUMN db.object_file.load_date IS 'Дата загрузки';
COMMENT ON COLUMN db.object_file.file_hash IS 'Хеш файла';
COMMENT ON COLUMN db.object_file.file_name IS 'Наименование файла';
COMMENT ON COLUMN db.object_file.file_path IS 'Путь к файлу на сервере';
COMMENT ON COLUMN db.object_file.file_size IS 'Размер файла';
COMMENT ON COLUMN db.object_file.file_date IS 'Дата и время файла';
COMMENT ON COLUMN db.object_file.file_body IS 'Содержимое файла (если нужно)';

CREATE INDEX ON db.object_file (object);

CREATE INDEX ON db.object_file (file_hash);
CREATE INDEX ON db.object_file (file_name);
CREATE INDEX ON db.object_file (file_path);
CREATE INDEX ON db.object_file (file_date);

--------------------------------------------------------------------------------
-- VIEW ObjectFile -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectFile (Id, Object, Hash, Name, Path, Size, Date, Body, Loaded)
AS
    SELECT id, object, file_hash, file_name, file_path, file_size, file_date, encode(file_body, 'base64'), load_date
      FROM db.object_file;

GRANT SELECT ON ObjectFile TO administrator;

--------------------------------------------------------------------------------
-- AddObjectFile ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddObjectFile (
  pObject	numeric,
  pHash		text,
  pName		text,
  pPath		text,
  pSize		numeric,
  pDate		timestamp,
  pBody		bytea DEFAULT null
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  INSERT INTO db.object_file (object, file_hash, file_name, file_path, file_size, file_date, file_body) 
  VALUES (pObject, pHash, pName, pPath, pSize, pDate, pBody) 
  RETURNING id INTO nId;
  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditObjectFile --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditObjectFile (
  pId		numeric,
  pHash		text,
  pName		text,
  pPath		text,
  pSize		numeric,
  pDate		timestamp,
  pBody		bytea DEFAULT null,
  pLoad		timestamp DEFAULT now()
) RETURNS	void
AS $$
BEGIN
  UPDATE db.object_file 
     SET load_date = pLoad,
         file_hash = pHash,
         file_name = pName,
         file_path = pPath, 
         file_size = pSize,
         file_date = pDate,
         file_body = pBody
   WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteObjectFile ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DeleteObjectFile (
  pId		numeric
) RETURNS	void
AS $$
BEGIN
  DELETE FROM db.object_file WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectFiles --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectFiles (
  pObject	numeric
) RETURNS	text[][]
AS $$
DECLARE
  arResult	text[][]; 
  i		    integer DEFAULT 1;
  r		    ObjectFile%rowtype;
BEGIN
  FOR r IN
    SELECT *
      FROM ObjectFile
     WHERE object = pObject
     ORDER BY Loaded desc, Path, Name
  LOOP
    arResult[i] := ARRAY[r.id, r.hash, r.name, r.path, r.size, r.date, r.body, r.loaded];
    i := i + 1;
  END LOOP;

  RETURN arResult;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectFilesJson ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectFilesJson (
  pObject	numeric
) RETURNS	json
AS $$
DECLARE
  arResult	json[]; 
  r		    record;
BEGIN
  FOR r IN
    SELECT Id, Hash, Name, Path, Size, Date, Body, Loaded
      FROM ObjectFile
     WHERE object = pObject
     ORDER BY Loaded desc, Path, Name
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectFilesJsonb ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectFilesJsonb (
  pObject	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectFilesJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- db.object_data_type ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_data_type (
    id			numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    code        varchar(30) NOT NULL,
    name 		varchar(50) NOT NULL,
    description	text
);

COMMENT ON TABLE db.object_data_type IS 'Тип произвольных данных объекта.';

COMMENT ON COLUMN db.object_data_type.id IS 'Идентификатор';
COMMENT ON COLUMN db.object_data_type.code IS 'Код';
COMMENT ON COLUMN db.object_data_type.name IS 'Наименование';
COMMENT ON COLUMN db.object_data_type.description IS 'Описание';

CREATE INDEX ON db.object_data_type (code);

INSERT INTO db.object_data_type (code, name, description) VALUES ('text', 'Текст', 'Произвольная строка');
INSERT INTO db.object_data_type (code, name, description) VALUES ('json', 'JSON', 'JavaScript Object Notation');
INSERT INTO db.object_data_type (code, name, description) VALUES ('xml', 'XML', 'eXtensible Markup Language');

--------------------------------------------------------------------------------
-- GetObjectDataType -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectDataType (
  pCode		varchar
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT id INTO nId FROM db.object_data_type WHERE code = pCode;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ObjectDataType --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectDataType (Id, Code, Name, Description)
AS
  SELECT id, code, name, description
    FROM db.object_data_type;

GRANT SELECT ON ObjectDataType TO administrator;

--------------------------------------------------------------------------------
-- db.object_data --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_data (
    id			numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    object		numeric(12) NOT NULL,
    type		numeric(12) NOT NULL,
    code        varchar(30) NOT NULL,
    data		text,
    CONSTRAINT fk_object_data_object FOREIGN KEY (object) REFERENCES db.object(id),
    CONSTRAINT fk_object_data_type FOREIGN KEY (type) REFERENCES db.object_data_type(id)
);

COMMENT ON TABLE db.object_data IS 'Произвольные данные объекта.';

COMMENT ON COLUMN db.object_data.object IS 'Объект';
COMMENT ON COLUMN db.object_data.type IS 'Тип произвольных данных объекта';
COMMENT ON COLUMN db.object_data.code IS 'Код';
COMMENT ON COLUMN db.object_data.data IS 'Данные';

CREATE INDEX ON db.object_data (object);
CREATE INDEX ON db.object_data (type);
CREATE INDEX ON db.object_data (code);

CREATE UNIQUE INDEX ON db.object_data (object, type, code);

--------------------------------------------------------------------------------
-- VIEW ObjectData -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectData (Id, Object, Type, TypeCode, TypeName, TypeDesc, Code, Data)
AS
  SELECT d.id, d.object, d.type, t.code, t.name, t.description, d.code, d.data
    FROM db.object_data d INNER JOIN db.object_data_type t ON t.id = d.type;

GRANT SELECT ON ObjectData TO administrator;

--------------------------------------------------------------------------------
-- AddObjectData ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddObjectData (
  pObject	numeric,
  pType		numeric,
  pCode		varchar,
  pData		text
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  INSERT INTO db.object_data (object, type, code, data) 
  VALUES (pObject, pType, pCode, pData) 
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditObjectData --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditObjectData (
  pId       numeric,
  pObject	numeric,
  pType		numeric,
  pCode		varchar,
  pData		text
) RETURNS	void
AS $$
BEGIN
  UPDATE db.object_data
     SET object = coalesce(pObject, object),
         type = coalesce(pType, type),
         code = coalesce(pCode, code),
         data = coalesce(pData, data)
   WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteObjectData ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DeleteObjectData (
  pId		numeric
) RETURNS	void
AS $$
BEGIN
  DELETE FROM db.object_data WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteObjectData ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DeleteObjectData (
  pObject	numeric,
  pType		numeric,
  pCode		varchar
) RETURNS	void
AS $$
BEGIN
  DELETE FROM db.object_data WHERE object = pObject AND type = pType AND code = pCode;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SetObjectData ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SetObjectData (
  pObject	numeric,
  pType		numeric,
  pCode		varchar,
  pData		text
) RETURNS	numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  SELECT d.id INTO nId FROM db.object_data d WHERE d.object = pObject AND d.type = pType AND d.code = pCode;

  IF pData IS NOT NULL THEN
    IF nId IS NULL THEN
      nId := AddObjectData(pObject, pType, pCode, pData);
    ELSE
      PERFORM EditObjectData(nId, pObject, pType, pCode, pData);
    END IF;
  ELSE
    PERFORM DeleteObjectData(nId);
  END IF;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectData ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectData (
  pObject	numeric,
  pType		numeric,
  pCode		varchar
) RETURNS	text
AS $$
DECLARE
  vData		text;
BEGIN
  SELECT data INTO vData FROM db.object_data WHERE object = pObject AND type = pType AND code = pCode;
  RETURN vData;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectData ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectData (
  pObject	numeric
) RETURNS	text[][]
AS $$
DECLARE
  arResult	text[][];
  i		    integer DEFAULT 1;
  r		    ObjectData%rowtype;
BEGIN
  FOR r IN
    SELECT *
      FROM ObjectData
     WHERE object = pObject
     ORDER BY type, code
  LOOP
    arResult[i] := ARRAY[r.id, r.typecode, r.code, r.data];
    i := i + 1;
  END LOOP;

  RETURN arResult;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectDataJson -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectDataJson (
  pObject	numeric
) RETURNS	json
AS $$
DECLARE
  arResult	json[];
  r		    record;
BEGIN
  FOR r IN
    SELECT Id, TypeCode AS type, Code, Data
      FROM ObjectData
     WHERE object = pObject
     ORDER BY type, code
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectDataJsonb ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectDataJsonb (
  pObject	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectDataJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- db.object_coordinates -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.object_coordinates (
    id			numeric(12) PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    object		numeric(12) NOT NULL,
    code        varchar(30) NOT NULL,
    name 		varchar(50) NOT NULL,
    latitude    numeric NOT NULL,
    longitude   numeric NOT NULL,
    accuracy    numeric NOT NULL DEFAULT 0,
    description	text,
    CONSTRAINT fk_object_coordinates_object FOREIGN KEY (object) REFERENCES db.object(id)
);

COMMENT ON TABLE db.object_coordinates IS 'Произвольные данные объекта.';

COMMENT ON COLUMN db.object_coordinates.object IS 'Объект';
COMMENT ON COLUMN db.object_coordinates.code IS 'Код';
COMMENT ON COLUMN db.object_coordinates.name IS 'Наименование';
COMMENT ON COLUMN db.object_coordinates.latitude IS 'Широта';
COMMENT ON COLUMN db.object_coordinates.longitude IS 'Долгота';
COMMENT ON COLUMN db.object_coordinates.accuracy IS 'Точность (высота над уровнем моря)';
COMMENT ON COLUMN db.object_coordinates.description IS 'Описание';

CREATE INDEX ON db.object_coordinates (object);
CREATE INDEX ON db.object_coordinates (code);

CREATE UNIQUE INDEX ON db.object_coordinates (object, code);

--------------------------------------------------------------------------------
-- VIEW ObjectCoordinates ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectCoordinates
AS
  SELECT * FROM db.object_coordinates;

GRANT SELECT ON ObjectCoordinates TO administrator;

--------------------------------------------------------------------------------
-- AddObjectCoordinates --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddObjectCoordinates (
  pObject   	numeric,
  pCode		    varchar,
  pName		    varchar,
  pLatitude     numeric,
  pLongitude    numeric,
  pAccuracy     numeric,
  pDescription  text
) RETURNS       numeric
AS $$
DECLARE
  nId		numeric;
BEGIN
  INSERT INTO db.object_coordinates (object, code, name, latitude, longitude, accuracy, description)
  VALUES (pObject, pCode, pName, pLatitude, pLongitude, pAccuracy, pDescription)
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditObjectCoordinates -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditObjectCoordinates (
  pId           numeric,
  pObject   	numeric,
  pCode		    varchar,
  pName		    varchar,
  pLatitude     numeric,
  pLongitude    numeric,
  pAccuracy     numeric,
  pDescription  text
) RETURNS       void
AS $$
BEGIN
  UPDATE db.object_coordinates
     SET object = coalesce(pObject, object),
         code = coalesce(pCode, code),
         name = coalesce(pName, name),
         latitude = coalesce(pLatitude, latitude),
         longitude = coalesce(pLongitude, longitude),
         accuracy = coalesce(pAccuracy, accuracy),
         description = coalesce(pDescription, description)
   WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteObjectCoordinates -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DeleteObjectCoordinates (
  pId		numeric
) RETURNS	void
AS $$
BEGIN
  DELETE FROM db.object_coordinates WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteObjectCoordinates -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION DeleteObjectCoordinates (
  pObject	numeric,
  pCode		varchar
) RETURNS	void
AS $$
BEGIN
  DELETE FROM db.object_coordinates WHERE object = pObject AND code = pCode;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectCoordinates --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectCoordinates (
  pObject       numeric,
  pCode         varchar
) RETURNS       ObjectCoordinates
AS $$
  SELECT * FROM ObjectCoordinates WHERE object = pObject AND code = pCode;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectCoordinates --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectCoordinates (
  pObject	numeric
) RETURNS	text[][]
AS $$
DECLARE
  arResult	text[][];
  i		    integer DEFAULT 1;
  r		    ObjectCoordinates%rowtype;
BEGIN
  FOR r IN
    SELECT *
      FROM ObjectCoordinates
     WHERE object = pObject
     ORDER BY code
  LOOP
    arResult[i] := ARRAY[r.id, r.code, r.name, r.latitude, r.longitude, r.accuracy, r.description];
    i := i + 1;
  END LOOP;

  RETURN arResult;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectCoordinatesJson ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectCoordinatesJson (
  pObject	numeric
) RETURNS	json
AS $$
DECLARE
  arResult	json[];
  r		    record;
BEGIN
  FOR r IN
    SELECT id, code, name, latitude, longitude, accuracy, description
      FROM ObjectCoordinates
     WHERE object = pObject
     ORDER BY code
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetObjectCoordinatesJsonb ---------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetObjectCoordinatesJsonb (
  pObject	numeric
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetObjectCoordinatesJson(pObject);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
