--------------------------------------------------------------------------------
-- ADDRESS ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.address (
    id          uuid PRIMARY KEY,
    reference   uuid NOT NULL REFERENCES db.reference(id) ON DELETE CASCADE,
    country     uuid NOT NULL REFERENCES db.country(id) ON DELETE CASCADE,
    kladr       text,
    index       text,
    region      text,
    district    text,
    city        text,
    settlement  text,
    street      text,
    house       text,
    building    text,
    structure   text,
    apartment   text,
    sortnum     integer NOT NULL
);

COMMENT ON TABLE db.address IS 'Адрес объекта.';

COMMENT ON COLUMN db.address.id IS 'Идентификатор';
COMMENT ON COLUMN db.address.reference IS 'Ссылка на документ';
COMMENT ON COLUMN db.address.kladr IS 'Код КЛАДР: ФФ СС РРР ГГГ ППП УУУУ. Где: ФФ - код страны; СС - код субъекта РФ; РРР - код района; ГГГ - код города; ППП - код населенного пункта; УУУУ - код улицы.';
COMMENT ON COLUMN db.address.index IS 'Почтовый индекс';
COMMENT ON COLUMN db.address.country IS 'Страна';
COMMENT ON COLUMN db.address.region IS 'Регион';
COMMENT ON COLUMN db.address.district IS 'Район';
COMMENT ON COLUMN db.address.city IS 'Город';
COMMENT ON COLUMN db.address.settlement IS 'Населённый пункт';
COMMENT ON COLUMN db.address.street IS 'Улица';
COMMENT ON COLUMN db.address.house IS 'Дом';
COMMENT ON COLUMN db.address.building IS 'Корпус';
COMMENT ON COLUMN db.address.structure IS 'Строение';
COMMENT ON COLUMN db.address.apartment IS 'Квартира';
COMMENT ON COLUMN db.address.sortnum IS 'Номер для сортировки';

CREATE INDEX ON db.address (reference);
CREATE INDEX ON db.address (country);
CREATE INDEX ON db.address (kladr);
CREATE INDEX ON db.address (index);
CREATE INDEX ON db.address (city);
CREATE INDEX ON db.address (street);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_address_insert()
RETURNS trigger AS $$
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.reference INTO NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_address_insert
  BEFORE INSERT ON db.address
  FOR EACH ROW
  EXECUTE PROCEDURE ft_address_insert();
