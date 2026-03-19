--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddClientMethods ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddClientMethods (
  pClass        uuid
)
RETURNS         void
AS $$
DECLARE
  uState        uuid;
  uMethod       uuid;

  rec_type      record;
  rec_state     record;
  rec_method    record;
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

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Approve');
        PERFORM EditMethodText(uMethod, 'Утвердить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Genehmigen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Approuver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Approvare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Aprobar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Close');
        PERFORM EditMethodText(uMethod, 'Закрыть', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Schließen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Fermer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Chiudere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cerrar', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'enabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Approved');
      PERFORM EditStateText(uState, 'Утверждён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Genehmigt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Approuvé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Approvato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Aprobado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('submit'), pVisible => false);

        PERFORM AddMethod(null, pClass, uState, GetAction('confirm'), pVisible => false );
        PERFORM AddMethod(null, pClass, uState, GetAction('reconfirm'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Close');
        PERFORM EditMethodText(uMethod, 'Закрыть', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Schließen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Fermer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Chiudere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cerrar', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'disabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Closed');
      PERFORM EditStateText(uState, 'Закрыт', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Geschlossen', GetLocale('de'));
      PERFORM EditStateText(uState, 'Fermé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Chiuso', GetLocale('it'));
      PERFORM EditStateText(uState, 'Cerrado', GetLocale('es'));

        PERFORM AddMethod(null, pClass, uState, GetAction('enable'));
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
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'enabled'));
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
-- AddClientEvents -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddClientEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент создан', 'EventClientCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент открыт', 'EventClientOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент изменён', 'EventClientEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент сохранён', 'EventClientSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент активен', 'EventClientEnable();');
    END IF;

    IF r.code = 'submit' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Передача данных', 'EventClientSubmit();');
    END IF;

    IF r.code = 'confirm' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Подтвердить адрес электронной почты', 'EventClientConfirm();');
    END IF;

    IF r.code = 'reconfirm' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Переподтвердить адрес электронной почты', 'EventClientReconfirm();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент не активен', 'EventClientDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент будет удалён', 'EventClientDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент восстановлен', 'EventClientRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент будет уничтожен', 'EventClientDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassClient -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassClient (
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
  uClass := AddClass(pParent, pEntity, 'client', 'Client', false);
  PERFORM EditClassText(uClass, 'Клиент', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Kunde', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Client', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Cliente', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Cliente', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'company.client', 'Company', 'Client - company.');
  PERFORM EditTypeText(uType, 'Компания', 'Клиент - компания.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Unternehmen', 'Kunde - Unternehmen.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Entreprise', 'Client - entreprise.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Azienda', 'Cliente - azienda.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Empresa', 'Cliente - empresa.', GetLocale('es'));

  -- Событие
  PERFORM AddClientEvents(uClass);

  -- Метод
  PERFORM AddClientMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityClient ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityClient (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uClass        uuid;
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('client', 'Client');
  PERFORM EditEntityText(uEntity, 'Клиент', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Kunde', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Client', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Cliente', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Cliente', null, GetLocale('es'));

  -- Класс
  uClass := CreateClassClient(pParent, uEntity);

  PERFORM CreateClassEmployee(uClass, uEntity);
  PERFORM CreateClassCustomer(uClass, uEntity);

  -- API
  PERFORM RegisterRoute('client', AddEndpoint('SELECT * FROM rest.client($1, $2);'));
  PERFORM RegisterRoute('employee', AddEndpoint('SELECT * FROM rest.employee($1, $2);'));
  PERFORM RegisterRoute('customer', AddEndpoint('SELECT * FROM rest.customer($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
