--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddPriceEvents --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddPriceEvents (
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
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена создана', 'EventPriceCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена открыта', 'EventPriceOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена изменена', 'EventPriceEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена сохранена', 'EventPriceSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена активна', 'EventPriceEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена отключена', 'EventPriceDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена удалена', 'EventPriceDelete();');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена восстановлена', 'EventPriceRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Цена будет уничтожена', 'EventPriceDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassPrice ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassPrice (
  pParent       uuid,
  pEntity       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uClass        uuid;
  uType         uuid;
BEGIN
  -- Класс
  uClass := AddClass(pParent, pEntity, 'price', 'Price', false);
  PERFORM EditClassText(uClass, 'Цена', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Preis', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Prix', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Prezzo', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Precio', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'one_off.price', 'One off', 'Charge a one-time fee.');
  PERFORM EditTypeText(uType, 'Один раз', 'Взимать единовременную плату.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Einmalig', 'Einmalige Gebühr erheben.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Unique', 'Facturer des frais uniques.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Una tantum', 'Addebitare una tariffa una tantum.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Único', 'Cobrar una tarifa única.', GetLocale('es'));

  uType := AddType(uClass, 'recurring.price', 'Recurring', 'Charge an ongoing fee.');
  PERFORM EditTypeText(uType, 'Повторяющийся', 'Взимать постоянную плату.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Wiederkehrend', 'Laufende Gebühr erheben.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Récurrent', 'Facturer des frais récurrents.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Ricorrente', 'Addebitare una tariffa ricorrente.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Recurrente', 'Cobrar una tarifa recurrente.', GetLocale('es'));

  -- Событие
  PERFORM AddPriceEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Active', 'Closed', 'Deleted', 'Activate', 'Close', 'Delete'], ARRAY['Создана', 'Активна', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityPrice -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityPrice (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('price', 'Price');
  PERFORM EditEntityText(uEntity, 'Цена', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Preis', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Prix', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Prezzo', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Precio', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassPrice(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('price', AddEndpoint('SELECT * FROM rest.price($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
