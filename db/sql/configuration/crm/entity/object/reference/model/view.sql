--------------------------------------------------------------------------------
-- Model -----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Model (Id, Reference, Code, Name, Description,
    Vendor, VendorCode, VendorName, VendorDescription,
    Category, CategoryCode, CategoryName, CategoryDescription
)
AS
  SELECT t.id, t.reference, r.code, rt.name, rt.description,
         t.vendor, rv.code, rvt.name, rvt.description,
         t.category, rc.code, rct.name, rct.description
    FROM db.model t INNER JOIN db.reference         r ON t.reference = r.id
                     LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                    INNER JOIN db.reference        rv ON t.vendor = rv.id
                     LEFT JOIN db.reference_text  rvt ON rvt.reference = rv.id AND rvt.locale = current_locale()
                     LEFT JOIN db.reference        rc ON t.category = rc.id
                     LEFT JOIN db.reference_text  rct ON rct.reference = rc.id AND rct.locale = current_locale();

GRANT SELECT ON Model TO administrator;

--------------------------------------------------------------------------------
-- AccessModel -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessModel
AS
WITH _access AS (
  WITH _membergroup AS (
    SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
  ) SELECT object
      FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'model'
                       INNER JOIN _membergroup m ON a.userid = m.userid
     GROUP BY object
     HAVING (bit_or(a.allow) & ~bit_or(a.deny)) & B'100' = B'100'
) SELECT o.* FROM db.model o INNER JOIN _access ac ON o.id = ac.object;

GRANT SELECT ON AccessModel TO administrator;

--------------------------------------------------------------------------------
-- ObjectModel -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectModel (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Vendor, VendorCode, VendorName, VendorDescription,
  Category, CategoryCode, CategoryName, CategoryDescription,
  Code, Name, Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, r.object, o.parent,
         o.entity, e.code, et.name,
         o.class, c.code, ct.label,
         o.type, y.code, ty.name, ty.description,
         t.vendor, rv.code, rvt.name, rvt.description,
         t.category, rc.code, rct.name, rct.description,
         r.code, rt.name, ot.label, rt.description,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         o.scope, sc.code, sc.name, sc.description
    FROM db.model t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                     LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                    INNER JOIN db.object            o ON t.reference = o.id
                     LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                    INNER JOIN db.entity            e ON o.entity = e.id
                     LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()
                    INNER JOIN db.class_tree        c ON o.class = c.id
                     LEFT JOIN db.class_text       ct ON ct.class = c.id AND ct.locale = current_locale()
                    INNER JOIN db.type              y ON o.type = y.id
                     LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                    INNER JOIN db.reference        rv ON t.vendor = rv.id
                     LEFT JOIN db.reference_text  rvt ON rvt.reference = rv.id AND rvt.locale = current_locale()
                     LEFT JOIN db.reference        rc ON t.category = rc.id
                     LEFT JOIN db.reference_text  rct ON rct.reference = rc.id AND rct.locale = current_locale()
                    INNER JOIN db.state_type       st ON o.state_type = st.id
                     LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                    INNER JOIN db.state             s ON o.state = s.id
                     LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                    INNER JOIN db.user              w ON o.owner = w.id
                    INNER JOIN db.user              u ON o.oper = u.id
                    INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectModel TO administrator;

--------------------------------------------------------------------------------
-- ModelProperty ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ModelProperty (
  Category, CategoryCode, CategoryName, CategoryDescription,
  Model, ModelCode, ModelName, ModelDescription,
  Measure, MeasureCode, MeasureName, MeasureDescription,
  Type, TypeCode, TypeName, TypeDescription,
  Property, PropertyCode, PropertyName, PropertyDescription,
  TypeValue, Value, Format, Sequence
)
AS
  SELECT m.category, m.categorycode, m.categoryname, m.categorydescription,
         mp.model, m.code, m.name, m.description,
         mp.measure, s.code, s.name, s.description,
         p.type, p.typecode, p.typename, p.typedescription,
         mp.property, p.code, p.name, p.description,
         (mp.value).vType,
         CASE
         WHEN (mp.value).vType = 0 THEN to_char((mp.value).vInteger, coalesce(mp.format, 'FM999999999990'))
         WHEN (mp.value).vType = 1 THEN to_char((mp.value).vNumeric, coalesce(mp.format, 'FM999999999990.00'))
         WHEN (mp.value).vType = 2 THEN to_char((mp.value).vDateTime, coalesce(mp.format, 'DD.MM.YYYY HH24:MI:SS'))
         WHEN (mp.value).vType = 3 THEN (mp.value).vString
         WHEN (mp.value).vType = 4 THEN (mp.value).vBoolean::text
         END,
         mp.format, mp.sequence
    FROM db.model_property mp INNER JOIN Model    m ON m.id = mp.model
                              INNER JOIN Property p ON p.id = mp.property
                               LEFT JOIN Measure  s ON s.id = mp.measure;

GRANT SELECT ON ModelProperty TO administrator;

--------------------------------------------------------------------------------
-- ModelPropertyJson -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ModelPropertyJson (ModelId, PropertyId, MeasureId,
  Property, Measure, TypeValue, Value, Format, Sequence
)
AS
  SELECT m.id, p.id, s.id,
         row_to_json(p), row_to_json(s),
         (mp.value).vType,
         CASE
         WHEN (mp.value).vType = 0 THEN to_char((mp.value).vInteger, coalesce(mp.format, 'FM999999999990'))
         WHEN (mp.value).vType = 1 THEN to_char((mp.value).vNumeric, coalesce(mp.format, 'FM999999999990.00'))
         WHEN (mp.value).vType = 2 THEN to_char((mp.value).vDateTime, coalesce(mp.format, 'DD.MM.YYYY HH24:MI:SS'))
         WHEN (mp.value).vType = 3 THEN (mp.value).vString
         WHEN (mp.value).vType = 4 THEN (mp.value).vBoolean::text
         END,
         mp.format, mp.sequence
    FROM db.model_property mp INNER JOIN Model    m ON m.id = mp.model
                              INNER JOIN Property p ON p.id = mp.property
                               LEFT JOIN Measure  s ON s.id = mp.measure;

GRANT SELECT ON ModelPropertyJson TO administrator;
