--------------------------------------------------------------------------------
-- Client ----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Client (Id, Document,
  Type, TypeCode, TypeName, TypeDescription,
  Company, CompanyCode, CompanyName, CompanyDescription,
  UserId, UserName, FullName, ShortName, LastName, FirstName, MiddleName,
  Code, Label, Description, Birthday, BirthPlace,
  Phone, PhoneVerified, Email, EmailVerified,
  Series, Number, Issued, IssuedDate, IssuedCode,
  INN, PIN, KPP, OGRN, BIC, Account, Address,
  Picture, Photo, Metadata
) AS
  SELECT t.id, c.document,
         o.type, y.code, ty.name, ty.description,
         t.company, c.code, cot.label, cdt.description,
         t.userid, u.username, cn.name, cn.short, cn.last, cn.first, cn.middle,
         t.code, ot.label, dt.description, t.birthday, t.birthplace,
         t.phone, p.phone_verified, t.email, p.email_verified,
         t.series, t.number, t.issued, t.issued_date, t.issued_code,
         t.inn, t.pin, t.kpp, t.ogrn, t.bic, t.account, t.address,
         p.picture, t.photo, t.metadata
    FROM db.client t INNER JOIN db.object            o ON o.id = t.document
                      LEFT JOIN db.object_text      ot ON ot.object = t.document AND ot.locale = current_locale()
                      LEFT JOIN db.document_text    dt ON dt.document = t.document AND dt.locale = current_locale()

                     INNER JOIN db.type              y ON y.id = o.type
                      LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                     INNER JOIN db.company           c ON c.id = t.company
                      LEFT JOIN db.object_text     cot ON cot.object = c.document AND cot.locale = current_locale()
                      LEFT JOIN db.document_text   cdt ON cdt.document = c.document AND cdt.locale = current_locale()

                      LEFT JOIN db.client_name      cn ON cn.client = t.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                      LEFT JOIN db.user              u ON u.id = t.userid
                      LEFT JOIN db.profile           p ON p.userid = t.userid AND p.scope = current_scope();

GRANT SELECT ON Client TO administrator;

--------------------------------------------------------------------------------
-- AccessClient ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessClient
AS
WITH _membergroup AS (
  SELECT current_userid() AS userid UNION SELECT userid FROM db.member_group WHERE member = current_userid()
) SELECT object
    FROM db.client t INNER JOIN db.aou         a ON a.object = t.id
                     INNER JOIN _membergroup   m ON a.userid = m.userid
   WHERE a.mask = B'100'
   GROUP BY object;

GRANT SELECT ON AccessClient TO administrator;

--------------------------------------------------------------------------------
-- ObjectClient ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectClient (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Company, CompanyCode, CompanyName, CompanyDescription,
  UserId, UserName, FullName, ShortName, LastName, FirstName, MiddleName,
  Code, Label, Description, Birthday, BirthPlace,
  Phone, PhoneVerified, Email, EmailVerified,
  Series, Number, Issued, IssuedDate, IssuedCode,
  INN, PIN, KPP, OGRN, BIC, Account, Address,
  Picture, Photo, Metadata,
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
         t.company, c.code, cot.label, cdt.description,
         t.userid, cu.username, cn.name, cn.short, cn.last, cn.first, cn.middle,
         t.code, ot.label, dt.description, t.birthday, t.birthplace,
         t.phone, p.phone_verified, t.email, p.email_verified,
         t.series, t.number, t.issued, t.issued_date, t.issued_code,
         t.inn, t.pin, t.kpp, t.ogrn, t.bic, t.account, t.address,
         p.picture, t.photo, t.metadata,
         o.state_type, st.code, stt.name,
         o.state, s.code, sst.label, o.udate,
         o.owner, w.username, w.name, o.pdate,
         o.oper, u.username, u.name, o.ldate,
         d.area, a.code, a.name, a.description,
         o.scope, sc.code, sc.name, sc.description
    FROM db.client t INNER JOIN db.document          d ON t.document = d.id
                      LEFT JOIN db.document_text    dt ON dt.document = d.id AND dt.locale = current_locale()

                     INNER JOIN db.object            o ON t.document = o.id
                      LEFT JOIN db.object_text      ot ON ot.object = o.id AND ot.locale = current_locale()

                     INNER JOIN db.entity            e ON o.entity = e.id
                      LEFT JOIN db.entity_text      et ON et.entity = e.id AND et.locale = current_locale()

                     INNER JOIN db.class_tree       ct ON o.class = ct.id
                      LEFT JOIN db.class_text      ctt ON ctt.class = ct.id AND ctt.locale = current_locale()

                     INNER JOIN db.type              y ON o.type = y.id
                      LEFT JOIN db.type_text        ty ON ty.type = y.id AND ty.locale = current_locale()

                     INNER JOIN db.company           c ON c.id = t.company
                      LEFT JOIN db.object_text     cot ON cot.object = c.document AND cot.locale = current_locale()
                      LEFT JOIN db.document_text   cdt ON cdt.document = c.document AND cdt.locale = current_locale()

                      LEFT JOIN db.client_name      cn ON cn.client = t.id AND cn.locale = current_locale() AND cn.validFromDate <= oper_date() AND cn.validToDate > oper_date()
                      LEFT JOIN db.user             cu ON cu.id = t.userid
                      LEFT JOIN db.profile           p ON p.userid = cu.id AND p.scope = current_scope()

                     INNER JOIN db.state_type       st ON o.state_type = st.id
                      LEFT JOIN db.state_type_text stt ON stt.type = st.id AND stt.locale = current_locale()

                     INNER JOIN db.state             s ON o.state = s.id
                      LEFT JOIN db.state_text      sst ON sst.state = s.id AND sst.locale = current_locale()

                     INNER JOIN db.user              w ON o.owner = w.id
                     INNER JOIN db.user              u ON o.oper = u.id

                     INNER JOIN DocumentAreaTree     a ON d.area = a.id
                     INNER JOIN db.scope            sc ON o.scope = sc.id;

GRANT SELECT ON ObjectClient TO administrator;
