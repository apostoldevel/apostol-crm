--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddInvoiceMethods -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddInvoiceMethods (
  pClass	    uuid
) RETURNS       void
AS $$
DECLARE
  nState        uuid;
  uMethod       uuid;

  rec_type      record;
  rec_state     record;
  rec_method	record;
BEGIN
  -- Операции (без учёта состояния)

  PERFORM DefaultMethods(pClass);

  -- Операции (с учётом состояния)

  FOR rec_type IN SELECT * FROM StateType
  LOOP

    CASE rec_type.code
    WHEN 'created' THEN

      nState := AddState(pClass, rec_type.id, rec_type.code, 'Unpaid');
      PERFORM EditStateText(nState, 'Не оплачен', GetLocale('ru'));
      PERFORM EditStateText(nState, 'Unbezahlt', GetLocale('de'));
      PERFORM EditStateText(nState, 'Non payé', GetLocale('fr'));
      PERFORM EditStateText(nState, 'Non pagato', GetLocale('it'));
      PERFORM EditStateText(nState, 'No pagado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('enable'), null, 'Pay');
        PERFORM EditMethodText(uMethod, 'Оплатить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Bezahlen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Payer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Pagare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Pagar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('close'), null, 'Close');
        PERFORM EditMethodText(uMethod, 'Закрыть', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Schließen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Fermer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Chiudere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cerrar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'enabled' THEN

      nState := AddState(pClass, rec_type.id, 'in_progress', 'Processing');
      PERFORM EditStateText(nState, 'В работе', GetLocale('ru'));
      PERFORM EditStateText(nState, 'In Bearbeitung', GetLocale('de'));
      PERFORM EditStateText(nState, 'En traitement', GetLocale('fr'));
      PERFORM EditStateText(nState, 'In elaborazione', GetLocale('it'));
      PERFORM EditStateText(nState, 'En proceso', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('fail'), null, 'Fail');
        PERFORM EditMethodText(uMethod, 'Неудача', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Fehlschlagen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Échouer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Fallire', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Fallar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('disable'), null, 'Confirm');
        PERFORM EditMethodText(uMethod, 'Подтвердить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Bestätigen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Confirmer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Confermare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Confirmar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

      nState := AddState(pClass, rec_type.id, 'failed', 'Failed');
      PERFORM EditStateText(nState, 'Ошибка', GetLocale('ru'));
      PERFORM EditStateText(nState, 'Fehlgeschlagen', GetLocale('de'));
      PERFORM EditStateText(nState, 'Échoué', GetLocale('fr'));
      PERFORM EditStateText(nState, 'Fallito', GetLocale('it'));
      PERFORM EditStateText(nState, 'Fallido', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('cancel'), null, 'Cancel');
        PERFORM EditMethodText(uMethod, 'Отменить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Stornieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Annuler', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Annullare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Cancelar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'disabled' THEN

      nState := AddState(pClass, rec_type.id, rec_type.code, 'Paid');
      PERFORM EditStateText(nState, 'Оплачен', GetLocale('ru'));
      PERFORM EditStateText(nState, 'Bezahlt', GetLocale('de'));
      PERFORM EditStateText(nState, 'Payé', GetLocale('fr'));
      PERFORM EditStateText(nState, 'Pagato', GetLocale('it'));
      PERFORM EditStateText(nState, 'Pagado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

      nState := AddState(pClass, rec_type.id, 'closed', 'Closed');
      PERFORM EditStateText(nState, 'Закрыт', GetLocale('ru'));
      PERFORM EditStateText(nState, 'Geschlossen', GetLocale('de'));
      PERFORM EditStateText(nState, 'Fermé', GetLocale('fr'));
      PERFORM EditStateText(nState, 'Chiuso', GetLocale('it'));
      PERFORM EditStateText(nState, 'Cerrado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'deleted' THEN

      nState := AddState(pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(nState, 'Удалён', GetLocale('ru'));
      PERFORM EditStateText(nState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(nState, 'Supprimé', GetLocale('fr'));
      PERFORM EditStateText(nState, 'Eliminato', GetLocale('it'));
      PERFORM EditStateText(nState, 'Eliminado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('restore'), null, 'Restore');
        PERFORM EditMethodText(uMethod, 'Восстановить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Wiederherstellen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Restaurer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Ripristinare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Restaurar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, nState, GetAction('drop'), null, 'Drop');
        PERFORM EditMethodText(uMethod, 'Уничтожить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Vernichten', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Détruire', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Distruggere', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Destruir', GetLocale('es'));

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
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'in_progress'));
        END IF;

        IF rec_method.actioncode = 'close' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'closed'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'in_progress' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;

        IF rec_method.actioncode = 'fail' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'failed'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'failed' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'cancel' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'created'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'closed' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'disabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
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
-- AddInvoiceEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddInvoiceEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату создан', 'EventInvoiceCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату открыт', 'EventInvoiceOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату изменён', 'EventInvoiceEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату сохранён', 'EventInvoiceSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату в работе', 'EventInvoiceEnable();');
    END IF;

    IF r.code = 'cancel' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату будет отменён', 'EventInvoiceCancel();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
    END IF;

    IF r.code = 'fail' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Сбой при выполнении операции', 'EventInvoiceFail();');
    END IF;

    IF r.code = 'close' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату закрыт', 'EventInvoiceClose();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату оплачен', 'EventInvoiceDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату будет удалён', 'EventInvoiceDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату восстановлен', 'EventInvoiceRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Счёт на оплату будет уничтожен', 'EventInvoiceDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassInvoice ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassInvoice (
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
  uClass := AddClass(pParent, pEntity, 'invoice', 'Invoice', false);
  PERFORM EditClassText(uClass, 'Счёт', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Rechnung', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Facture', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Fattura', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Factura', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'payment.invoice', 'Service payment', 'Invoice for service payment.');
  PERFORM EditTypeText(uType, 'Оплата услуг', 'Счёт на оплату услуг.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Dienstleistungszahlung', 'Rechnung für Dienstleistungszahlung.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Paiement de service', 'Facture de paiement de service.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Pagamento servizi', 'Fattura per pagamento servizi.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Pago de servicio', 'Factura de pago de servicio.', GetLocale('es'));

  uType := AddType(uClass, 'top-up.invoice', 'Top-up', 'Account top-up.');
  PERFORM EditTypeText(uType, 'Пополнение', 'Пополнение лицевого счёта.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Aufladung', 'Kontoaufladung.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Rechargement', 'Rechargement de compte.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Ricarica', 'Ricarica del conto.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Recarga', 'Recarga de cuenta.', GetLocale('es'));

  -- Событие
  PERFORM AddInvoiceEvents(uClass);

  -- Метод
  PERFORM AddInvoiceMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityInvoice ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityInvoice (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('invoice', 'Invoice');
  PERFORM EditEntityText(uEntity, 'Счёт', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Rechnung', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Facture', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Fattura', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Factura', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassInvoice(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('invoice', AddEndpoint('SELECT * FROM rest.invoice($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
