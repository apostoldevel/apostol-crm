--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddPropertyEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddPropertyEvents (
  pClass        uuid
)
RETURNS         void
AS $$
DECLARE
  r             record;

  uParent       uuid;
  uEvent        uuid;
BEGIN
  uParent := GetEventType('parent');
  uEvent := GetEventType('event');

  FOR r IN SELECT * FROM Action
  LOOP

    IF r.code = 'create' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property created', 'EventPropertyCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property opened', 'EventPropertyOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property edited', 'EventPropertyEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property saved', 'EventPropertySave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property enabled', 'EventPropertyEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property disabled', 'EventPropertyDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property will be deleted', 'EventPropertyDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property restored', 'EventPropertyRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Property will be destroyed', 'EventPropertyDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassProperty ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassProperty (
  pParent       uuid,
  pEntity       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uType         uuid;
  uClass        uuid;
BEGIN
  -- Класс
  uClass := AddClass(pParent, pEntity, 'property', 'Property', false);
  PERFORM EditClassText(uClass, 'Свойство', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Eigenschaft', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Propriété', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Proprietà', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Propiedad', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'string.property', 'String', 'String type.');
  PERFORM EditTypeText(uType, 'Строка', 'Символьный тип.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Zeichenkette', 'Zeichenkettentyp.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Chaîne', 'Type chaîne de caractères.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Stringa', 'Tipo stringa.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Cadena', 'Tipo cadena de caracteres.', GetLocale('es'));

  uType := AddType(uClass, 'integer.property', 'Integer', 'Integer type.');
  PERFORM EditTypeText(uType, 'Целое число', 'Целочисленный тип.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Ganzzahl', 'Ganzzahltyp.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Entier', 'Type entier.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Intero', 'Tipo intero.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Entero', 'Tipo entero.', GetLocale('es'));

  uType := AddType(uClass, 'numeric.property', 'Numeric', 'Arbitrary precision number.');
  PERFORM EditTypeText(uType, 'Вещественное число', 'Число с произвольной точностью.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Numerisch', 'Zahl mit beliebiger Genauigkeit.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Numérique', 'Nombre à précision arbitraire.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Numerico', 'Numero a precisione arbitraria.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Numérico', 'Número de precisión arbitraria.', GetLocale('es'));

--  PERFORM AddType(uClass, 'money.property', 'Денежная сумма', 'Денежный тип.');

  uType := AddType(uClass, 'datetime.property', 'Date and time', 'Date and time type.');
  PERFORM EditTypeText(uType, 'Дата и время', 'Тип даты и времени.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Datum und Uhrzeit', 'Datums- und Uhrzeittyp.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Date et heure', 'Type date et heure.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Data e ora', 'Tipo data e ora.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Fecha y hora', 'Tipo fecha y hora.', GetLocale('es'));

  uType := AddType(uClass, 'boolean.property', 'Boolean', 'Boolean type.');
  PERFORM EditTypeText(uType, 'Логический', 'Логический тип.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Boolesch', 'Boolescher Typ.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Booléen', 'Type booléen.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Booleano', 'Tipo booleano.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Booleano', 'Tipo booleano.', GetLocale('es'));

--  PERFORM AddType(uClass, 'enum.property', 'Перечисляемый', 'Тип перечислений.');
--  PERFORM AddType(uClass, 'uuid.property', 'UUID', 'Универсальный уникальный идентификатор.');
--  PERFORM AddType(uClass, 'json.property', 'JSON', 'Тип JSON.');
--  PERFORM AddType(uClass, 'xml.property', 'XML', 'Тип XML.');

  -- Событие
  PERFORM AddPropertyEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Enabled', 'Disabled', 'Deleted', 'Open', 'Close', 'Delete'], ARRAY['Создано', 'Доступно', 'Недоступно', 'Удалено', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityProperty --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityProperty (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('property', 'Property');
  PERFORM EditEntityText(uEntity, 'Свойство', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Eigenschaft', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Propriété', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Proprietà', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Propiedad', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassProperty(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('property', AddEndpoint('SELECT * FROM rest.property($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
