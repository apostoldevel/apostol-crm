--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddAccountEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddAccountEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт создан', 'EventAccountCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт открыт', 'EventAccountOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт изменён', 'EventAccountEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт сохранён', 'EventAccountSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт открыт', 'EventAccountEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт закрыт', 'EventAccountDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт будет удалён', 'EventAccountDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт восстановлен', 'EventAccountRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт будет уничтожена', 'EventAccountDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassAccount ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassAccount (
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
  uClass := AddClass(pParent, pEntity, 'account', 'Account', false);
  PERFORM EditClassText(uClass, 'Лицевой счёт', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Konto', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Compte', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Conto', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Cuenta', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'active.account', 'Active', 'Active account.');
  PERFORM EditTypeText(uType, 'Активный', 'Активный счёт.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Aktiv', 'Aktives Konto.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Actif', 'Compte actif.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Attivo', 'Conto attivo.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Activo', 'Cuenta activa.', GetLocale('es'));

  uType := AddType(uClass, 'passive.account', 'Passive', 'Passive account.');
  PERFORM EditTypeText(uType, 'Пассивный', 'Пассивный счёт.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Passiv', 'Passives Konto.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Passif', 'Compte passif.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Passivo', 'Conto passivo.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Pasivo', 'Cuenta pasiva.', GetLocale('es'));

  uType := AddType(uClass, 'active-passive.account', 'Active-passive', 'Active-Passive account.');
  PERFORM EditTypeText(uType, 'Активно-пассивный', 'Активно-пассивный счёт.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Aktiv-passiv', 'Aktiv-passives Konto.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Actif-passif', 'Compte actif-passif.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Attivo-passivo', 'Conto attivo-passivo.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Activo-pasivo', 'Cuenta activa-pasiva.', GetLocale('es'));

  -- Событие
  PERFORM AddAccountEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Created', 'Opened', 'Closed', 'Deleted', 'Open', 'Close', 'Delete'], ARRAY['Создан', 'Открыт', 'Закрыт', 'Удалён', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityAccount ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityAccount (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('account', 'Account');
  PERFORM EditEntityText(uEntity, 'Счёт', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Konto', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Compte', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Conto', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Cuenta', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassAccount(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('account', AddEndpoint('SELECT * FROM rest.account($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
