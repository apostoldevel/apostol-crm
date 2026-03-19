--------------------------------------------------------------------------------
-- ClientName ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ClientName (Id, Client,
  Locale, LocaleCode, LocaleName, LocaleDescription,
  FullName, ShortName, LastName, FirstName, MiddleName,
  ValidFromDate, ValidToDate
)
AS
  SELECT n.id, n.client,
         n.locale, l.code, l.name, l.description,
         n.name, n.short, n.last, n.first, n.middle,
         n.validfromdate, n.validToDate
    FROM db.client_name n INNER JOIN db.locale l ON l.id = n.locale;

GRANT SELECT ON ClientName TO administrator;
