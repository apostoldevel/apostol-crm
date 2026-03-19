--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddTransactionMethods -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddTransactionMethods (
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

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Created');
      PERFORM EditStateText(uState, 'Создана', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstellt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Créée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Creata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Creada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Processing');
        PERFORM EditMethodText(uMethod, 'Обработать', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Verarbeiten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Traiter', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Elaborare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Procesar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'enabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'processing', 'Processing');
      PERFORM EditStateText(uState, 'Обработка', GetLocale('ru'));
      PERFORM EditStateText(uState, 'In Bearbeitung', GetLocale('de'));
      PERFORM EditStateText(uState, 'En traitement', GetLocale('fr'));
      PERFORM EditStateText(uState, 'In elaborazione', GetLocale('it'));
      PERFORM EditStateText(uState, 'En proceso', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Complete');
        PERFORM EditMethodText(uMethod, 'Завершить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Abschließen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Terminer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Completare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Completar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete', null, false);
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'disabled' THEN

      uState := SetState(null, pClass, rec_type.id, 'succeeded', 'Succeeded');
      PERFORM EditStateText(uState, 'Завершена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erfolgreich', GetLocale('de'));
      PERFORM EditStateText(uState, 'Réussie', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Riuscita', GetLocale('it'));
      PERFORM EditStateText(uState, 'Exitosa', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('refund'), null, 'Refund');
        PERFORM EditMethodText(uMethod, 'Вернуть', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Erstatten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Rembourser', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Rimborsare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Reembolsar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete', null, false);
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'deleted' THEN

      uState := SetState(null, pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore');
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Wiederherstellen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Restaurer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Ripristinare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Restaurar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop');
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Vernichten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Détruire', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Distruggere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Destruir', GetLocale('es'));

      uState := SetState(null, pClass, rec_type.id, 'refunded', 'Refunded');
      PERFORM EditStateText(uState, 'Возвращена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstattet', GetLocale('de'));
      PERFORM EditStateText(uState, 'Remboursée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Rimborsata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Reembolsada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore');
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop');
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));

      uState := SetState(null, pClass, rec_type.id, 'canceled', 'Canceled');
      PERFORM EditStateText(uState, 'Отменена', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Storniert', GetLocale('de'));
      PERFORM EditStateText(uState, 'Annulée', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Annullata', GetLocale('it'));
      PERFORM EditStateText(uState, 'Cancelada', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('restore'), null, 'Restore');
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('drop'), null, 'Drop');
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));

    END CASE;

  END LOOP;

  PERFORM DefaultTransition(pClass);

  FOR rec_state IN SELECT * FROM State WHERE class = pClass
  LOOP
    CASE rec_state.code
    WHEN 'created' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'processing'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'processing' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'succeeded'));
        END IF;

        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'canceled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'succeeded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'refund' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'refunded'));
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

    WHEN 'refunded' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'restore' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;
      END LOOP;

    WHEN 'canceled' THEN

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
-- AddTransactionEvents --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddTransactionEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция создана', 'EventTransactionCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция открыта', 'EventTransactionOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция изменена', 'EventTransactionEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция сохранена', 'EventTransactionSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция открыта', 'EventTransactionEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция закрыта', 'EventTransactionDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция будет удалена', 'EventTransactionDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция восстановлена', 'EventTransactionRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция будет уничтожена', 'EventTransactionDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'cancel' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция будет отменена', 'EventTransactionCancel();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'refund' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Транзакция будет возвращена', 'EventTransactionRefund();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassTransaction ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassTransaction (
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
  uClass := AddClass(pParent, pEntity, 'transaction', 'Transaction', false);
  PERFORM EditClassText(uClass, 'Транзакция', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Transaktion', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Transaction', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Transazione', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Transacción', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'service.transaction', 'Service', 'Service transaction.');
  PERFORM EditTypeText(uType, 'Услуга', 'Транзакция обслуживания.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Dienstleistung', 'Dienstleistungstransaktion.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Service', 'Transaction de service.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Servizio', 'Transazione di servizio.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Servicio', 'Transacción de servicio.', GetLocale('es'));

  -- Событие
  PERFORM AddTransactionEvents(uClass);

  -- Метод
  PERFORM AddTransactionMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityTransaction -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityTransaction (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('transaction', 'Transaction');
  PERFORM EditEntityText(uEntity, 'Транзакция', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Transaktion', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Transaction', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Transazione', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Transacción', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassTransaction(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('transaction', AddEndpoint('SELECT * FROM rest.transaction($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
