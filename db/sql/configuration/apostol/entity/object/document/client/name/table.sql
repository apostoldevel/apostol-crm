--------------------------------------------------------------------------------
-- db.client_name --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.client_name (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    client          uuid NOT NULL REFERENCES db.client(id) ON DELETE CASCADE,
    locale          uuid NOT NULL REFERENCES db.locale(id) ON DELETE RESTRICT,
    name            text NOT NULL,
    short           text,
    first           text,
    last            text,
    middle          text,
    validFromDate   timestamptz DEFAULT Now() NOT NULL,
    validToDate     timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.client_name IS 'Locale-aware client name with validity period. Supports both personal and company names.';

COMMENT ON COLUMN db.client_name.client IS 'Reference to the owning client.';
COMMENT ON COLUMN db.client_name.locale IS 'Locale for this name variant.';
COMMENT ON COLUMN db.client_name.name IS 'Full name: company name or concatenated personal name (last + first + middle).';
COMMENT ON COLUMN db.client_name.short IS 'Short or abbreviated company name.';
COMMENT ON COLUMN db.client_name.first IS 'First (given) name for individuals.';
COMMENT ON COLUMN db.client_name.last IS 'Last (family) name for individuals.';
COMMENT ON COLUMN db.client_name.middle IS 'Middle (patronymic) name for individuals.';
COMMENT ON COLUMN db.client_name.validFromDate IS 'Start of the validity period for this name.';
COMMENT ON COLUMN db.client_name.validToDate IS 'End of the validity period for this name.';

--------------------------------------------------------------------------------

CREATE INDEX ON db.client_name (client);
CREATE INDEX ON db.client_name (locale);
CREATE INDEX ON db.client_name (name);
CREATE INDEX ON db.client_name (name text_pattern_ops);
CREATE INDEX ON db.client_name (short);
CREATE INDEX ON db.client_name (short text_pattern_ops);
CREATE INDEX ON db.client_name (first);
CREATE INDEX ON db.client_name (first text_pattern_ops);
CREATE INDEX ON db.client_name (last);
CREATE INDEX ON db.client_name (last text_pattern_ops);
CREATE INDEX ON db.client_name (middle);
CREATE INDEX ON db.client_name (middle text_pattern_ops);
CREATE INDEX ON db.client_name (first, last, middle);

CREATE INDEX ON db.client_name (locale, validFromDate, validToDate);

CREATE UNIQUE INDEX ON db.client_name (client, locale, validFromDate, validToDate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION db.ft_client_name_insert_update()
RETURNS trigger AS $$
DECLARE
  uUserId    uuid;
BEGIN
  IF NEW.locale IS NULL THEN
    NEW.locale := current_locale();
  END IF;

  IF NEW.name IS NULL THEN
    IF NEW.last IS NOT NULL THEN
      NEW.name := NEW.last;
    END IF;

    IF NEW.first IS NOT NULL THEN
      IF NEW.name IS NULL THEN
        NEW.name := NEW.first;
      ELSE
        NEW.name := NEW.name || ' ' || NEW.first;
      END IF;
    END IF;

    IF NEW.middle IS NOT NULL THEN
      IF NEW.name IS NOT NULL THEN
        NEW.name := NEW.name || ' ' || NEW.middle;
      END IF;
    END IF;
  END IF;

  IF NEW.name IS NULL THEN
    SELECT code INTO NEW.name FROM db.client WHERE id = NEW.client;
  END IF;

  UPDATE db.object_text SET label = NEW.name WHERE object = NEW.client AND locale = NEW.locale;

  SELECT UserId INTO uUserId FROM db.client WHERE id = NEW.client;
  IF uUserId IS NOT NULL THEN
    UPDATE db.user SET name = NEW.name WHERE id = uUserId;
    UPDATE db.profile
       SET given_name = NEW.first,
           family_name = NEW.last,
           patronymic_name = NEW.middle
     WHERE userId = uUserId;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_client_name_insert_update
  BEFORE INSERT OR UPDATE ON db.client_name
  FOR EACH ROW
  EXECUTE PROCEDURE db.ft_client_name_insert_update();
