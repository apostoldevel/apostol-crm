--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCurrencyEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCurrencyEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency created', 'EventCurrencyCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency opened', 'EventCurrencyOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency edited', 'EventCurrencyEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency saved', 'EventCurrencySave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency enabled', 'EventCurrencyEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency disabled', 'EventCurrencyDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency will be deleted', 'EventCurrencyDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency restored', 'EventCurrencyRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Currency will be destroyed', 'EventCurrencyDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCurrency ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCurrency (
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
  uClass := AddClass(pParent, pEntity, 'currency', 'Currency', false);
  PERFORM EditClassText(uClass, 'Валюта', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Währung', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Devise', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Valuta', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Moneda', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'iso.currency', 'ISO', 'ISO 4217.');
  PERFORM EditTypeText(uType, 'ISO', 'ISO 4217.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'ISO', 'ISO 4217.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'ISO', 'ISO 4217.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'ISO', 'ISO 4217.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'ISO', 'ISO 4217.', GetLocale('es'));

  uType := AddType(uClass, 'crypto.currency', 'Cryptocurrency', 'Cryptocurrency.');
  PERFORM EditTypeText(uType, 'Криптовалюта', 'Криптовалюта.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Kryptowährung', 'Kryptowährung.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Cryptomonnaie', 'Cryptomonnaie.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Criptovaluta', 'Criptovaluta.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Criptomoneda', 'Criptomoneda.', GetLocale('es'));

  uType := AddType(uClass, 'unit.currency', 'Conventional unit', 'Conventional unit of measurement.');
  PERFORM EditTypeText(uType, 'Условная единица', 'Условная единица измерения.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Konventionelle Einheit', 'Konventionelle Maßeinheit.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Unité conventionnelle', 'Unité de mesure conventionnelle.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Unità convenzionale', 'Unità di misura convenzionale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Unidad convencional', 'Unidad de medida convencional.', GetLocale('es'));

  -- Событие
  PERFORM AddCurrencyEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Opened', 'Closed', 'Deleted', 'Open', 'Close', 'Delete'], ARRAY['Создана', 'Открыта', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityCurrency --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityCurrency (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('currency', 'Currency');
  PERFORM EditEntityText(uEntity, 'Валюта', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Währung', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Devise', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Valuta', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Moneda', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassCurrency(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('currency', AddEndpoint('SELECT * FROM rest.currency($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InitCurrency ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitCurrency()
RETURNS         void
AS $$
DECLARE
  uType         uuid;
BEGIN
  uType := GetType('iso.currency');

  PERFORM CreateCurrency(null, GetType('iso.currency'), 'RUB', 'Рубль', 'Российский рубль.', 643);
  PERFORM CreateCurrency(null, GetType('iso.currency'), 'USD', 'Доллар США', 'Доллар США.', 840);
  PERFORM CreateCurrency(null, GetType('iso.currency'), 'EUR', 'Евро', 'Евро.', 978);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
