--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddIdentityMethods ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddIdentityMethods (
  pClass            uuid
)
RETURNS             void
AS $$
DECLARE
  uState            uuid;
  uMethod           uuid;

  rec_type          record;
  rec_state         record;
  rec_method        record;
BEGIN
  -- Операции (без учёта состояния)

  PERFORM DefaultMethods(pClass);

  -- Операции (с учётом состояния)

  FOR rec_type IN SELECT * FROM StateType
  LOOP

    CASE rec_type.code
    WHEN 'created' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Created');
      PERFORM EditStateText(uState, 'Создан', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstellt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Créé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Creato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Creado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Activate');
        PERFORM EditMethodText(uMethod, 'В работу', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Aktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Activer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Attivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Activar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Archive');
        PERFORM EditMethodText(uMethod, 'В архив', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Archivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Archiver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Archiviare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Archivar', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'enabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Active');
      PERFORM EditStateText(uState, 'Действует', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Aktiv', GetLocale('de'));
      PERFORM EditStateText(uState, 'Actif', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Attivo', GetLocale('it'));
      PERFORM EditStateText(uState, 'Activo', GetLocale('es'));

		PERFORM AddMethod(null, pClass, uState, GetAction('check'), null, 'Проверить', pVisible => false);
		PERFORM AddMethod(null, pClass, uState, GetAction('expire'), null, 'Просрочить', pVisible => false);

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Archive');
        PERFORM EditMethodText(uMethod, 'В архив', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Archivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Archiver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Archiviare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Archivar', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

	  uState := AddState(pClass, rec_type.id, 'expired', 'Expired');
      PERFORM EditStateText(uState, 'Просрочен', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Abgelaufen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Expiré', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Scaduto', GetLocale('it'));
      PERFORM EditStateText(uState, 'Expirado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Activate');
        PERFORM EditMethodText(uMethod, 'В работу', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Aktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Activer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Attivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Activar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Archive');
        PERFORM EditMethodText(uMethod, 'В архив', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Archivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Archiver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Archiviare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Archivar', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'disabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Archived');
      PERFORM EditStateText(uState, 'В архиве', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Archiviert', GetLocale('de'));
      PERFORM EditStateText(uState, 'Archivé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Archiviato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Archivado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('return'));
        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'deleted' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('restore'));
        PERFORM AddMethod(null, pClass, uState, GetAction('drop'));

    END CASE;

  END LOOP;

  PERFORM DefaultTransition(pClass);

  -- Переходы из состояния в состояние

  FOR rec_state IN SELECT * FROM State WHERE class = pClass
  LOOP
    CASE rec_state.code
    WHEN 'created' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'enabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'expire' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'expired'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'expired' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'disabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'return' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'deleted' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;
      END LOOP;
    END CASE;
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AddIdentityEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddIdentityEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность создано', 'EventIdentityCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность открыт', 'EventIdentityOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность изменён', 'EventIdentityEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность сохранён', 'EventIdentitySave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность доступен', 'EventIdentityEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность недоступен', 'EventIdentityDisable();');
    END IF;

	IF r.code = 'check' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Проверить документ удостоверяющий личность', 'EventIdentityCheck();');
	END IF;

	IF r.code = 'return' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность возвращён', 'EventIdentityReturn();');
	END IF;

	IF r.code = 'expire' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность просрочен', 'EventIdentityExpire();');
	END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность будет удалён', 'EventIdentityDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность восстановлен', 'EventIdentityRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Документ удостоверяющий личность будет уничтожен', 'EventIdentityDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassIdentity ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassIdentity (
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
  uClass := AddClass(pParent, pEntity, 'identity', 'Identity', false);
  PERFORM EditClassText(uClass, 'Идентификатор', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Ausweis', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Identité', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Identità', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Identidad', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'passport.identity', 'Passport', 'Identity document.');
  PERFORM EditTypeText(uType, 'Паспорт', 'Удостоверение личности.', GetLocale('ru'));

  uType := AddType(uClass, 'driver.identity', 'Driver license', 'Driver license.');
  PERFORM EditTypeText(uType, 'Водительское удостоверение', 'Водительское удостоверение в Российской Федерации.', GetLocale('ru'));

  uType := AddType(uClass, 'inn.identity', 'TIN', 'Taxpayer identification number.');
  PERFORM EditTypeText(uType, 'ИНН', 'Идентификационный номер налогоплательщика.', GetLocale('ru'));

  uType := AddType(uClass, 'pin.identity', 'SNILS', 'Individual insurance account number.');
  PERFORM EditTypeText(uType, 'СНИЛС', 'Страховой номер индивидуального лицевого счёта.', GetLocale('ru'));

  uType := AddType(uClass, 'kpp.identity', 'KPP', 'Tax registration reason code.');
  PERFORM EditTypeText(uType, 'КПП', 'Код причины постановки на учёт.', GetLocale('ru'));

  uType := AddType(uClass, 'ogrn.identity', 'OGRN', 'Primary state registration number.');
  PERFORM EditTypeText(uType, 'ОГРН', 'Основной государственный регистрационный номер.', GetLocale('ru'));

  uType := AddType(uClass, 'ogrnip.identity', 'OGRNIP', 'Primary state registration number of individual entrepreneur.');
  PERFORM EditTypeText(uType, 'ОГРНИП', 'Основной государственный регистрационный номер индивидуального предпринимателя.', GetLocale('ru'));

  uType := AddType(uClass, 'account.identity', 'Settlement account', 'Settlement account.');
  PERFORM EditTypeText(uType, 'Расчетный счёт', 'Расчетный счёт.', GetLocale('ru'));

  uType := AddType(uClass, 'cor-account.identity', 'Correspondent account', 'Correspondent account.');
  PERFORM EditTypeText(uType, 'К/с', 'Корреспондентский счёт.', GetLocale('ru'));

  uType := AddType(uClass, 'bic.identity', 'BIC', 'Bank identification code.');
  PERFORM EditTypeText(uType, 'БИК', 'Банковский идентификационный код.', GetLocale('ru'));

  -- Событие
  PERFORM AddIdentityEvents(uClass);

  -- Метод
  PERFORM AddIdentityMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityIdentity --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityIdentity (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('identity', 'Identity');
  PERFORM EditEntityText(uEntity, 'Документ удостоверяющий личность', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Ausweis', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Identité', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Identità', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Identidad', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassIdentity(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('identity', AddEndpoint('SELECT * FROM rest.identity($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
