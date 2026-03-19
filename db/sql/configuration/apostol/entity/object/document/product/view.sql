--------------------------------------------------------------------------------
-- Product ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Product
AS
  SELECT t.id, o.parent, t.document,
         o.class, ct.code AS ClassCode, ctt.label AS ClassLabel,
         o.type, y.code AS TypeCode, ty.name AS TypeName, ty.description AS TypeDescription,
         o.state_type AS StateType, st.code AS StateTypeCode, stt.name AS StateTypeName,
         o.state, s.code AS StateCode, sst.label AS StateLabel,
         o.pdate AS Created, o.udate AS LastUpdate, o.ldate AS OperDate,
         t.code, t.name, ot.label, dt.description,
         t.default_price AS DefaultPrice, t.tax_code AS TaxCode, t.url, t.metadata
    FROM db.product t INNER JOIN db.object            o ON o.id = t.document
                       LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                       LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale();

GRANT SELECT ON Product TO administrator;

--------------------------------------------------------------------------------
-- AccessProduct ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessProduct
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.product t INNER JOIN db.aou         a ON a.object = t.id
                      INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessProduct TO administrator;

--------------------------------------------------------------------------------
-- ObjectProduct ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectProduct (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Code, Name, Label, Description,
  DefaultPrice, TaxCode, URL, MetaData,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, d.object, o.parent,
         o.entity, e.code, et.name,
         o.class, ct.code, ctt.label,
         o.type, y.code, ty.name, ty.description,
         t.code, t.name, ot.label, dt.description,
         t.default_price, t.tax_code, t.url, t.metadata,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.product t INNER JOIN db.document          d ON t.document = d.id
                       LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                      INNER JOIN db.object            o ON t.document = o.id
                       LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                      INNER JOIN db.entity            e ON o.entity = e.id
                       LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                      INNER JOIN db.class_tree       ct ON o.class = ct.id
                       LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                      INNER JOIN db.type              y ON o.type = y.id
                       LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                      INNER JOIN db.state_type       st ON o.state_type = st.id
                       LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                      INNER JOIN db.state             s ON o.state = s.id
                       LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                      INNER JOIN db.user              w ON o.owner = w.id
                      INNER JOIN db.user              u ON o.oper = u.id

                      INNER JOIN DocumentAreaTree     a ON d.area = a.id
                      INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectProduct TO administrator;
