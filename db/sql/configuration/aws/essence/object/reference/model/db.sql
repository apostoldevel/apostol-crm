--------------------------------------------------------------------------------
-- MODEL -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.model --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.model (
    id			    numeric(12) PRIMARY KEY,
    reference		numeric(12) NOT NULL,
    vendor          numeric(12) NOT NULL,
    CONSTRAINT fk_model_reference FOREIGN KEY (reference) REFERENCES db.reference(id)
);

COMMENT ON TABLE db.model IS 'Модель.';

COMMENT ON COLUMN db.model.id IS 'Идентификатор.';
COMMENT ON COLUMN db.model.reference IS 'Справочник.';
COMMENT ON COLUMN db.model.vendor IS 'Производитель (поставщик).';

CREATE INDEX ON db.model (reference);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_model_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.ID IS NULL OR NEW.ID = 0 THEN
    SELECT NEW.REFERENCE INTO NEW.ID;
  END IF;

  RAISE DEBUG 'Создана модель Id: %', NEW.ID;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

CREATE TRIGGER t_model_insert
  BEFORE INSERT ON db.model
  FOR EACH ROW
  EXECUTE PROCEDURE ft_model_insert();

--------------------------------------------------------------------------------
-- CreateModel -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт модель
 * @param {numeric} pParent - Идентификатор объекта родителя
 * @param {numeric} pType - Идентификатор типа
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pVendor - Производитель
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION CreateModel (
  pParent       numeric,
  pType         numeric,
  pCode         varchar,
  pName         varchar,
  pVendor       numeric,
  pDescription	text default null
) RETURNS       numeric
AS $$
DECLARE
  nReference	numeric;
  nClass        numeric;
  nMethod       numeric;
BEGIN
  nReference := CreateReference(pParent, pType, pCode, pName, pDescription);

  INSERT INTO db.model (reference, vendor)
  VALUES (nReference, pVendor);

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
-- EditModel -------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет модель
 * @param {numeric} pId - Идентификатор
 * @param {numeric} pParent - Идентификатор объекта родителя
 * @param {numeric} pType - Идентификатор типа
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {numeric} pVendor - Производитель
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION EditModel (
  pId           numeric,
  pParent       numeric default null,
  pType         numeric default null,
  pCode         varchar default null,
  pName         varchar default null,
  pVendor       numeric default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  nClass        numeric;
  nMethod       numeric;
BEGIN
  PERFORM EditReference(pId, pParent, pType, pCode, pName, pDescription);

  UPDATE db.model
     SET vendor = coalesce(pVendor, vendor)
   WHERE id = pId;

  SELECT class INTO nClass FROM db.type WHERE id = pType;

  nMethod := GetMethod(nClass, null, GetAction('edit'));
  PERFORM ExecuteMethod(pId, nMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetModel ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetModel (
  pCode		varchar
) RETURNS 	numeric
AS $$
BEGIN
  RETURN GetReference(pCode || '.model');
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION GetModelVendor ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetModelVendor (
  pId       numeric
) RETURNS 	numeric
AS $$
  SELECT vendor FROM db.model WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- Model ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Model (Id, Reference, Code, Name, Description,
    Vendor, VendorCode, VendorName, VendorDescription
)
AS
  SELECT m.id, m.reference, mr.code, mr.name, mr.description, m.vendor,
         vr.code, vr.name, vr.description
    FROM db.model m INNER JOIN db.reference mr ON mr.id = m.reference
                    INNER JOIN db.reference vr ON vr.id = m.vendor;

GRANT SELECT ON Model TO administrator;

--------------------------------------------------------------------------------
-- ObjectModel ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectModel (Id, Object, Parent,
  Essence, EssenceCode, EssenceName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Vendor, VendorCode, VendorName, VendorDescription,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate
)
AS
  SELECT m.id, r.object, r.parent,
         r.essence, r.essencecode, r.essencename,
         r.class, r.classcode, r.classlabel,
         r.type, r.typecode, r.typename, r.typedescription,
         r.code, r.name, r.label, r.description,
         m.vendor, m.vendorcode, m.vendorname, m.vendordescription,
         r.statetype, r.statetypecode, r.statetypename,
         r.state, r.statecode, r.statelabel, r.lastupdate,
         r.owner, r.ownercode, r.ownername, r.created,
         r.oper, r.opercode, r.opername, r.operdate
    FROM Model m INNER JOIN ObjectReference r ON r.id = m.reference;

GRANT SELECT ON ObjectModel TO administrator;
