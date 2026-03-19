--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddDeviceMethods ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddDeviceMethods (
  pClass        uuid
)
RETURNS void
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
      PERFORM EditStateText(uState, 'Создано', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Erstellt', GetLocale('de'));
      PERFORM EditStateText(uState, 'Créé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Creato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Creado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Enable');
        PERFORM EditMethodText(uMethod, 'Включить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Aktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Activer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Attivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Activar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'enabled' THEN

      uState := AddState(pClass, rec_type.id, 'available', 'Available');
      PERFORM EditStateText(uState, 'Доступно', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Verfügbar', GetLocale('de'));
      PERFORM EditStateText(uState, 'Disponible', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Disponibile', GetLocale('it'));
      PERFORM EditStateText(uState, 'Disponible', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('heartbeat'), null, 'Heartbeat', null, false);
        PERFORM EditMethodText(uMethod, 'Heartbeat', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('available'), null, 'Available', null, false);
        PERFORM EditMethodText(uMethod, 'Доступно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('unavailable'), null, 'Unavailable', null, false);
        PERFORM EditMethodText(uMethod, 'Недоступно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('faulted'), null, 'Faulted', null, false);
        PERFORM EditMethodText(uMethod, 'Неисправно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Disable');
        PERFORM EditMethodText(uMethod, 'Отключить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Deaktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Désactiver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Disattivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Desactivar', GetLocale('es'));

      uState := AddState(pClass, rec_type.id, 'unavailable', 'Unavailable');
      PERFORM EditStateText(uState, 'Недоступно', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Nicht verfügbar', GetLocale('de'));
      PERFORM EditStateText(uState, 'Indisponible', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Non disponibile', GetLocale('it'));
      PERFORM EditStateText(uState, 'No disponible', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('heartbeat'), null, 'Heartbeat', null, false);
        PERFORM EditMethodText(uMethod, 'Heartbeat', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('available'), null, 'Available', null, false);
        PERFORM EditMethodText(uMethod, 'Доступно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('unavailable'), null, 'Unavailable', null, false);
        PERFORM EditMethodText(uMethod, 'Недоступно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('faulted'), null, 'Faulted', null, false);
        PERFORM EditMethodText(uMethod, 'Неисправно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Disable');
        PERFORM EditMethodText(uMethod, 'Отключить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Deaktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Désactiver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Disattivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Desactivar', GetLocale('es'));

      uState := AddState(pClass, rec_type.id, 'faulted', 'Faulted');
      PERFORM EditStateText(uState, 'Неисправно', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Fehlerhaft', GetLocale('de'));
      PERFORM EditStateText(uState, 'En panne', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Guasto', GetLocale('it'));
      PERFORM EditStateText(uState, 'Averiado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('heartbeat'), null, 'Heartbeat', null, false);
        PERFORM EditMethodText(uMethod, 'Heartbeat', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('available'), null, 'Available', null, false);
        PERFORM EditMethodText(uMethod, 'Доступно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('unavailable'), null, 'Unavailable');
        PERFORM EditMethodText(uMethod, 'Недоступно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('faulted'), null, 'Faulted', null, false);
        PERFORM EditMethodText(uMethod, 'Неисправно', GetLocale('ru'));

        uMethod := AddMethod(null, pClass, uState, GetAction('disable'), null, 'Disable');
        PERFORM EditMethodText(uMethod, 'Отключить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Deaktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Désactiver', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Disattivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Desactivar', GetLocale('es'));

    WHEN 'disabled' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Disabled');
      PERFORM EditStateText(uState, 'Отключено', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Deaktiviert', GetLocale('de'));
      PERFORM EditStateText(uState, 'Désactivé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Disattivato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Desactivado', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('enable'), null, 'Enable');
        PERFORM EditMethodText(uMethod, 'Включить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Aktivieren', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Activer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Attivare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Activar', GetLocale('es'));

        uMethod := AddMethod(null, pClass, uState, GetAction('delete'), null, 'Delete');
        PERFORM EditMethodText(uMethod, 'Удалить', GetLocale('ru'));
        PERFORM EditMethodText(uMethod, 'Löschen', GetLocale('de'));
        PERFORM EditMethodText(uMethod, 'Supprimer', GetLocale('fr'));
        PERFORM EditMethodText(uMethod, 'Eliminare', GetLocale('it'));
        PERFORM EditMethodText(uMethod, 'Eliminar', GetLocale('es'));

    WHEN 'deleted' THEN

      uState := AddState(pClass, rec_type.id, rec_type.code, 'Deleted');
      PERFORM EditStateText(uState, 'Удалено', GetLocale('ru'));
      PERFORM EditStateText(uState, 'Gelöscht', GetLocale('de'));
      PERFORM EditStateText(uState, 'Supprimé', GetLocale('fr'));
      PERFORM EditStateText(uState, 'Eliminato', GetLocale('it'));
      PERFORM EditStateText(uState, 'Eliminado', GetLocale('es'));

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
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'unavailable'));
        END IF;

        IF rec_method.actioncode = 'delete' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'deleted'));
        END IF;
      END LOOP;

    WHEN 'available' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'unavailable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'unavailable'));
        END IF;

        IF rec_method.actioncode = 'faulted' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'faulted'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;
      END LOOP;

    WHEN 'unavailable' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'available' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'available'));
        END IF;

        IF rec_method.actioncode = 'faulted' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'faulted'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;
      END LOOP;

    WHEN 'faulted' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'available' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'available'));
        END IF;

        IF rec_method.actioncode = 'unavailable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'unavailable'));
        END IF;

        IF rec_method.actioncode = 'disable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'disabled'));
        END IF;
      END LOOP;

    WHEN 'disabled' THEN

      FOR rec_method IN SELECT * FROM Method WHERE state = rec_state.id
      LOOP
        IF rec_method.actioncode = 'enable' THEN
          PERFORM AddTransition(rec_state.id, rec_method.id, GetState(pClass, 'unavailable'));
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
-- AddDeviceEvents -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddDeviceEvents (
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
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство создано', 'EventDeviceCreate();');
	END IF;

	IF r.code = 'open' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство открыто', 'EventDeviceOpen();');
	END IF;

	IF r.code = 'edit' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство изменено', 'EventDeviceEdit();');
	END IF;

	IF r.code = 'save' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство сохранено', 'EventDeviceSave();');
	END IF;

	IF r.code = 'enable' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство включено', 'EventDeviceEnable();');
	END IF;

	IF r.code = 'heartbeat' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство на связи', 'EventDeviceHeartbeat();');
	END IF;

	IF r.code = 'available' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство доступно', 'EventDeviceAvailable();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	END IF;

	IF r.code = 'unavailable' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство недоступно', 'EventDeviceUnavailable();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	END IF;

	IF r.code = 'faulted' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство неисправно', 'EventDeviceFaulted();');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Смена состояния', 'ChangeObjectState();');
	END IF;

	IF r.code = 'disable' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство отключено', 'EventDeviceDisable();');
	END IF;

	IF r.code = 'delete' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство будет удалено', 'EventDeviceDelete();');
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	END IF;

	IF r.code = 'restore' THEN
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство восстановлено', 'EventDeviceRestore();');
	END IF;

	IF r.code = 'drop' THEN
	  PERFORM AddEvent(pClass, uEvent, r.id, 'Устройство будет уничтожено', 'EventDeviceDrop();');
	  PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
	END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassDevice -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassDevice (
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
  uClass := AddClass(pParent, pEntity, 'device', 'Device', false);
  PERFORM EditClassText(uClass, 'Устройство', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Gerät', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Appareil', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Dispositivo', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Dispositivo', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'auto.device', 'Automobile', 'Automobile.');
  PERFORM EditTypeText(uType, 'Автомобиль', 'Автомобиль.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Automobil', 'Automobil.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Automobile', 'Automobile.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Automobile', 'Automobile.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Automóvil', 'Automóvil.', GetLocale('es'));

  uType := AddType(uClass, 'tractor.device', 'Tractor', 'Tractor.');
  PERFORM EditTypeText(uType, 'Трактор', 'Трактор.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Traktor', 'Traktor.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Tracteur', 'Tracteur.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Trattore', 'Trattore.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Tractor', 'Tractor.', GetLocale('es'));

  uType := AddType(uClass, 'mobile.device', 'Mobile', 'Mobile device.');
  PERFORM EditTypeText(uType, 'Мобильное', 'Мобильное устройство.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Mobil', 'Mobilgerät.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Mobile', 'Appareil mobile.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Mobile', 'Dispositivo mobile.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Móvil', 'Dispositivo móvil.', GetLocale('es'));

  uType := AddType(uClass, 'iot.device', 'IoT', 'Internet thing.');
  PERFORM EditTypeText(uType, 'IoT', 'Интернет-вещь.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'IoT', 'Internet-Ding.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'IoT', 'Objet connecté.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'IoT', 'Oggetto connesso.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'IoT', 'Objeto conectado.', GetLocale('es'));

  uType := AddType(uClass, 'unknown.device', 'Unknown', 'Unknown device.');
  PERFORM EditTypeText(uType, 'Неизвестное', 'Неизвестное устройство.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Unbekannt', 'Unbekanntes Gerät.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Inconnu', 'Appareil inconnu.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Sconosciuto', 'Dispositivo sconosciuto.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Desconocido', 'Dispositivo desconocido.', GetLocale('es'));

  -- Событие
  PERFORM AddDeviceEvents(uClass);

  -- Метод
  PERFORM AddDeviceMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityDevice ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityDevice (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  PERFORM SetAction(null, 'heartbeat', 'Сердцебиение');

  PERFORM SetAction(null, 'available', 'Доступен');
  PERFORM SetAction(null, 'preparing', 'Подготовка');
  PERFORM SetAction(null, 'finishing', 'Завершение');
  PERFORM SetAction(null, 'reserved', 'Зарезервирован');
  PERFORM SetAction(null, 'unavailable', 'Недоступен');
  PERFORM SetAction(null, 'faulted', 'Ошибка');

  -- Сущность
  uEntity := AddEntity('device', 'Device');
  PERFORM EditEntityText(uEntity, 'Устройство', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Gerät', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Appareil', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Dispositivo', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Dispositivo', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassDevice(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('device', AddEndpoint('SELECT * FROM rest.device($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
