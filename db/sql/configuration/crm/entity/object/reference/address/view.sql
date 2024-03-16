--------------------------------------------------------------------------------
-- Address ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Address (Id, Reference,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Kladr, Index, Country, Region, District, City, Settlement,
  Street, House, Building, Structure, Apartment, SortNum,
  Scope, ScopeCode, ScopeName, ScopeDescription
) AS
  SELECT t.id, t.reference,
         o.type, y.code, ty.name, ty.description,
         r.code, rt.name, ot.label, rt.description,
         t.kladr, t.index, t.country, t.region, t.district, t.city, t.settlement,
         t.street, t.house, t.building, t.structure, t.apartment, t.sortnum,
         r.scope, sc.code, sc.name, sc.description
    FROM db.address t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                       LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                      INNER JOIN db.object            o ON t.reference = o.id
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON Address TO administrator;

--------------------------------------------------------------------------------
-- AccessAddress ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessAddress
AS
WITH _access AS (
   WITH _membergroup AS (
	 SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
   ) SELECT object
       FROM db.aou AS a INNER JOIN db.entity    e ON a.entity = e.id AND e.code = 'address'
                        INNER JOIN _membergroup m ON a.userid = m.userid
      WHERE a.mask & B'100' = B'100'
      GROUP BY object
) SELECT t.* FROM db.address t INNER JOIN _access ac ON t.id = ac.object;

GRANT SELECT ON AccessAddress TO administrator;

--------------------------------------------------------------------------------
-- ObjectAddress ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectAddress (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  Kladr, Index, Country, Region, District, City, Settlement,
  Street, House, Building, Structure, Apartment, SortNum,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Scope, ScopeCode, ScopeName, ScopeDescription
) AS
  SELECT t.id, r.object, o.parent,
         o.entity, e.code, et.name,
         o.class, c.code, ct.label,
         o.type, y.code, ty.name, ty.description,
         r.code, rt.name, ot.label, rt.description,
         t.kladr, t.index, t.country, t.region, t.district, t.city, t.settlement,
         t.street, t.house, t.building, t.structure, t.apartment, t.sortnum,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         o.scope, sc.code, sc.name, sc.description
    FROM AccessAddress t INNER JOIN db.reference         r ON t.reference = r.id AND r.scope = current_scope()
                          LEFT JOIN db.reference_text   rt ON rt.reference = r.id AND rt.locale = current_locale()
                         INNER JOIN db.object            o ON t.reference = o.id
                          LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()
                         INNER JOIN db.entity            e ON o.entity = e.id
                          LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()
                         INNER JOIN db.class_tree        c ON o.class = c.id
                          LEFT JOIN db.class_text       ct ON ct.class = c.id AND ct.locale = current_locale()
                         INNER JOIN db.type              y ON o.type = y.id
                          LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                         INNER JOIN db.state_type       st ON o.state_type = st.id
                          LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()
                         INNER JOIN db.state             s ON o.state = s.id
                          LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()
                         INNER JOIN db.user              w ON o.owner = w.id
                         INNER JOIN db.user              u ON o.oper = u.id
                         INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectAddress TO administrator;

--------------------------------------------------------------------------------
-- ObjectAddresses -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectAddresses (Id, Object, Address, Key,
    Kladr, Index, Country, Region, District, City, Settlement, Street, House,
    Building, Structure, Apartment, SortNum,
    ValidFromDate, ValidToDate
)
AS
  SELECT ol.id, ol.object, ol.linked, ol.key,
         a.kladr, a.index, a.country, a.region, a.district, a.city, a.settlement, a.street, a.house,
         a.building, a.structure, a.apartment, a.sortnum,
         ol.validFromDate, ol.validToDate
    FROM db.object_link ol INNER JOIN db.address a ON ol.linked = a.id;

GRANT SELECT ON ObjectAddresses TO administrator;
