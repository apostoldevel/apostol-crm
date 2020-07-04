--------------------------------------------------------------------------------
-- TARIFF ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.tariff -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.tariff (
    id			    numeric(12) PRIMARY KEY,
    reference		numeric(12) NOT NULL,
    cost            numeric(12,4) NOT NULL,
    CONSTRAINT fk_tariff_reference FOREIGN KEY (reference) REFERENCES db.reference(id)
);

COMMENT ON TABLE db.tariff IS 'Тариф.';

COMMENT ON COLUMN db.tariff.id IS 'Идентификатор.';
COMMENT ON COLUMN db.tariff.reference IS 'Справочник.';
COMMENT ON COLUMN db.tariff.cost IS 'Стоимость.';

CREATE INDEX ON db.tariff (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_tariff_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.ID IS NULL OR NEW.ID = 0 THEN
    SELECT NEW.REFERENCE INTO NEW.ID;
  END IF;

  RAISE DEBUG 'Создан тариф Id: %', NEW.ID;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_tariff_insert
  BEFORE INSERT ON db.tariff
  FOR EACH ROW
  EXECUTE PROCEDURE ft_tariff_insert();

--------------------------------------------------------------------------------
-- CreateTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт тариф
 * @param {numeric} pParent - Идентификатор объекта родителя
 * @param {numeric} pType - Идентификатор типа
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pCost - Стоимость
 * @param {text} pDescription - Описание
 * @return {id} - Id или ошибку
 */
CREATE OR REPLACE FUNCTION CreateTariff (
  pParent       numeric,
  pType         numeric,
  pCode         varchar,
  pName         varchar,
  pCost         numeric,
  pDescription	text default null
) RETURNS       numeric
AS $$
DECLARE
  nReference	numeric;
  nClass        numeric;
  nMethod       numeric;
BEGIN
  nReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.tariff (reference, cost)
  VALUES (nReference, pCost);

  SELECT class INTO nClass FROM db.type WHERE id = pType;

  nMethod := GetMethod(nClass, null, GetAction('create'));
  PERFORM ExecuteMethod(nReference, nMethod);

  nMethod := GetMethod(nClass, null, GetAction('enable'));
  PERFORM ExecuteMethod(nReference, nMethod);

  RETURN nReference;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditTariff ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет тариф
 * @param {numeric} pId - Идентификатор
 * @param {numeric} pParent - Идентификатор объекта родителя
 * @param {numeric} pType - Идентификатор типа
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pCost - Стоимость
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditTariff (
  pId           numeric,
  pParent       numeric default null,
  pType         numeric default null,
  pCode         varchar default null,
  pName         varchar default null,
  pCost         numeric default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  nClass        numeric;
  nMethod       numeric;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription);

  UPDATE db.tariff
     SET cost = coalesce(pCost, cost)
   WHERE id = pId;

  SELECT class INTO nClass FROM db.type WHERE id = pType;

  nMethod := GetMethod(nClass, null, GetAction('edit'));
  PERFORM ExecuteMethod(pId, nMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetTariff ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTariff (
  pCode		varchar
) RETURNS 	numeric
AS $$
BEGIN
  RETURN GetReference(pCode || '.tariff');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetTariffCost ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetTariffCost (
  pId       numeric
) RETURNS 	numeric
AS $$
  SELECT cost FROM db.tariff WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- Tariff ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Tariff (Id, Reference, Code, Name, Description, Cost)
AS
  SELECT c.id, c.reference, d.code, d.name, d.description, c.cost
    FROM db.tariff c INNER JOIN db.reference d ON d.id = c.reference;

GRANT SELECT ON Tariff TO administrator;

--------------------------------------------------------------------------------
-- ObjectTariff ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectTariff (Id, Object, Parent,
  Essence, EssenceCode, EssenceName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Cost,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate
)
AS
  SELECT t.id, r.object, r.parent,
         r.essence, r.essencecode, r.essencename,
         r.class, r.classcode, r.classlabel,
         r.type, r.typecode, r.typename, r.typedescription,
         r.code, r.name, r.label, r.description,
         t.cost,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate
    FROM db.tariff t INNER JOIN ObjectReference r ON r.id = t.reference;

GRANT SELECT ON ObjectTariff TO administrator;
