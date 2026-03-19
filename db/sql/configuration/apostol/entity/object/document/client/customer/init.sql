--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCustomerMethods ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCustomerMethods (
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

        PERFORM AddMethod(null, pClass, uState, GetAction('delete'));

    WHEN 'enabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Approved');
      PERFORM EditStateText(uState, 'Утверждён', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Genehmigt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Approuvé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Approvato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Aprobado', GetLocale('es'));

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
-- AddCustomerEvents -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCustomerEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент создан', 'EventCustomerCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент открыт', 'EventCustomerOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент изменён', 'EventCustomerEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент сохранён', 'EventCustomerSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент активен', 'EventCustomerEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент не активен', 'EventCustomerDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент будет удалён', 'EventCustomerDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент восстановлен', 'EventCustomerRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Клиент будет уничтожен', 'EventCustomerDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCustomer ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCustomer (
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
  uClass := AddClass(pParent, pEntity, 'customer', 'Customer', false);
  PERFORM EditClassText(uClass, 'Клиент', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Kunde', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Client', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Cliente', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Cliente', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'person.customer', 'Natural person', 'A natural person.');
  PERFORM EditTypeText(uType, 'ФЛ', 'Физическое лицо.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Natürliche Person', 'Natürliche Person.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Personne physique', 'Personne physique.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Persona fisica', 'Persona fisica.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Persona física', 'Persona física.', GetLocale('es'));

  uType := AddType(uClass, 'individual.customer', 'Individual', 'Individual entrepreneur.');
  PERFORM EditTypeText(uType, 'ИП', 'Индивидуальный предприниматель.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Einzelunternehmer', 'Einzelunternehmer.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Entrepreneur individuel', 'Entrepreneur individuel.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Imprenditore individuale', 'Imprenditore individuale.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Empresario individual', 'Empresario individual.', GetLocale('es'));

  uType := AddType(uClass, 'organization.customer', 'Organization', 'Organization.');
  PERFORM EditTypeText(uType, 'ЮЛ', 'Юридическое лицо.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Organisation', 'Organisation.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Organisation', 'Organisation.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Organizzazione', 'Organizzazione.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Organización', 'Organización.', GetLocale('es'));

  -- Событие
  PERFORM AddCustomerEvents(uClass);

  -- Метод
  PERFORM AddCustomerMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
