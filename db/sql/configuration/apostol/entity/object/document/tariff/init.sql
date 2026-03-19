--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddTariffEvents -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddTariffEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф создан', 'EventTariffCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф открыт', 'EventTariffOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф изменён', 'EventTariffEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф сохранён', 'EventTariffSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф доступен', 'EventTariffEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф недоступен', 'EventTariffDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф будет удалён', 'EventTariffDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф восстановлен', 'EventTariffRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Тариф будет уничтожен', 'EventTariffDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassTariff -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassTariff (
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
  uClass := AddClass(pParent, pEntity, 'tariff', 'Tariff', false);
  PERFORM EditClassText(uClass, 'Тариф', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Tarif', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Tarif', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Tariffa', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Tarifa', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'system.tariff', 'System', 'System tariff.');
  PERFORM EditTypeText(uType, 'Системный', 'Системный тариф.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'System', 'Systemtarif.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Système', 'Tarif système.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Sistema', 'Tariffa di sistema.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Sistema', 'Tarifa del sistema.', GetLocale('es'));

  uType := AddType(uClass, 'custom.tariff', 'Custom', 'Custom tariff.');
  PERFORM EditTypeText(uType, 'Пользовательский', 'Пользовательский тариф.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Benutzerdefiniert', 'Benutzerdefinierter Tarif.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Personnalisé', 'Tarif personnalisé.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Personalizzato', 'Tariffa personalizzata.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Personalizado', 'Tarifa personalizada.', GetLocale('es'));

  -- Событие
  PERFORM AddTariffEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityTariff ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityTariff (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('tariff', 'Tariff');
  PERFORM EditEntityText(uEntity, 'Тариф', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Tarif', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Tarif', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Tariffa', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Tarifa', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassTariff(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('tariff', AddEndpoint('SELECT * FROM rest.tariff($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InitTariffSchema ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitTariffScheme()
RETURNS         void
AS $$
BEGIN
  PERFORM DoDisable(id) FROM Product WHERE statetype = '00000000-0000-4000-b001-000000000002'::uuid;

  PERFORM SetTariffScheme(GetService('time.service'), GetCurrency('RUB'), 'default', 0.1, 0, 0);
  PERFORM SetTariffScheme(GetService('volume.service'), GetCurrency('RUB'), 'default', 0.01, 0, 0);

  PERFORM DoEnable(id) FROM Product WHERE statetype IN ('00000000-0000-4000-b001-000000000001'::uuid, '00000000-0000-4000-b001-000000000003'::uuid);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
