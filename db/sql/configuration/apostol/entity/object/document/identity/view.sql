--------------------------------------------------------------------------------
-- Identity --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Identity (Id, Document,
  Type, TypeCode, TypeName, TypeDescription,
  Country, CountryCode, CountryName, CountryDescription,
  Client, UserName, FullName, FirstName, LastName, MiddleName, Birthday, BirthPlace, Picture,
  Series, Number, Identity, Code, Issued, Date, Photo,
  ReminderDate, ValidFromDate, ValidToDate
)
AS
  SELECT t.id, t.document,
         t.type, y.code, ty.name, ty.description,
         t.country, cr.code, crt.name, crt.description,
         t.client, cl.code, cn.name, cn.first, cn.last, cn.middle, cl.birthday, cl.birthplace, p.picture,
         t.series, t.number, t.identity, t.code, t.issued, t.date, encode(t.photo, 'base64'),
         t.reminderdate, NULLIF(t.validfromdate, MINDATE()), NULLIF(t.validtodate, MAXDATE())
    FROM db.identity t INNER JOIN db.type              y ON t.type = y.id
                        LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()
                       INNER JOIN db.reference        cr ON t.country = cr.id
                        LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()
                       INNER JOIN db.client           cl ON cl.id = t.client
                        LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                        LEFT JOIN db.profile           p ON p.userid = cl.userid AND p.scope = current_scope();

GRANT SELECT ON Identity TO administrator;

--------------------------------------------------------------------------------
-- AccessIdentity --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessIdentity
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.identity t INNER JOIN db.aou         a ON a.object = t.id
                       INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessIdentity TO administrator;

--------------------------------------------------------------------------------
-- ObjectIdentity --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectIdentity (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Country, CountryCode, CountryName, CountryDescription,
  Client, UserName, FullName, FirstName, LastName, MiddleName, Birthday, BirthPlace, Picture,
  Series, Number, Identity, Code, Issued, Date, Photo,
  ReminderDate, ValidFromDate, ValidToDate,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
) AS
  SELECT t.id, d.object, o.parent,
         o.entity, e.code, et.name,
         o.class, ct.code, ctt.label,
         o.type, y.code, ty.name, ty.description,
         t.country, cr.code, crt.name, crt.description,
         t.client, cl.code, cn.name, cn.first, cn.last, cn.middle, cl.birthday, cl.birthplace, p.picture,
         t.series, t.number, t.identity, t.code, t.issued, t.date, encode(t.photo, 'base64'),
         t.reminderdate, NULLIF(t.validfromdate, MINDATE()), NULLIF(t.validtodate, MAXDATE()),
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.identity t INNER JOIN db.document          d ON t.document = d.id
                        LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                       INNER JOIN db.object            o ON t.document = o.id
                        LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                       INNER JOIN db.entity            e ON o.entity = e.id
                        LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                       INNER JOIN db.class_tree       ct ON o.class = ct.id
                        LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                       INNER JOIN db.type              y ON o.type = y.id
                        LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                       INNER JOIN db.reference        cr ON t.country = cr.id
                        LEFT JOIN db.reference_text  crt ON crt.reference = cr.id AND crt.locale = current_locale()

                       INNER JOIN db.client           cl ON cl.id = t.client
                        LEFT JOIN db.client_name      cn ON cn.client = cl.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                        LEFT JOIN db.profile           p ON p.userid = cl.userid AND p.scope = o.scope

                       INNER JOIN db.state_type       st ON o.state_type = st.id
                        LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                       INNER JOIN db.state             s ON o.state = s.id
                        LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                       INNER JOIN db.user              w ON o.owner = w.id
                       INNER JOIN db.user              u ON o.oper = u.id

                       INNER JOIN DocumentAreaTree     a ON d.area = a.id
                       INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectIdentity TO administrator;
