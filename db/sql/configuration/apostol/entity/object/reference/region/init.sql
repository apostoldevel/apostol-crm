--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddRegionEvents -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddRegionEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region created', 'EventRegionCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region opened', 'EventRegionOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region edited', 'EventRegionEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region saved', 'EventRegionSave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region enabled', 'EventRegionEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region disabled', 'EventRegionDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region will be deleted', 'EventRegionDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region restored', 'EventRegionRestore();');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Region will be destroyed', 'EventRegionDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'Parent class events');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassRegion -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassRegion (
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
  uClass := AddClass(pParent, pEntity, 'region', 'Region', false);
  PERFORM EditClassText(uClass, 'Регион', GetLocale('ru'));
  PERFORM EditClassText(uClass, 'Region', GetLocale('de'));
  PERFORM EditClassText(uClass, 'Région', GetLocale('fr'));
  PERFORM EditClassText(uClass, 'Regione', GetLocale('it'));
  PERFORM EditClassText(uClass, 'Región', GetLocale('es'));

  -- Тип
  uType := AddType(uClass, 'code.region', 'Region codes', 'Region codes.');
  PERFORM EditTypeText(uType, 'Коды регионов', 'Коды регионов РФ.', GetLocale('ru'));
  PERFORM EditTypeText(uType, 'Regionscodes', 'Regionscodes.', GetLocale('de'));
  PERFORM EditTypeText(uType, 'Codes régionaux', 'Codes régionaux.', GetLocale('fr'));
  PERFORM EditTypeText(uType, 'Codici regionali', 'Codici regionali.', GetLocale('it'));
  PERFORM EditTypeText(uType, 'Códigos regionales', 'Códigos regionales.', GetLocale('es'));

  -- Событие
  PERFORM AddRegionEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityRegion ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityRegion (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('region', 'Region');
  PERFORM EditEntityText(uEntity, 'Регион', null, GetLocale('ru'));
  PERFORM EditEntityText(uEntity, 'Region', null, GetLocale('de'));
  PERFORM EditEntityText(uEntity, 'Région', null, GetLocale('fr'));
  PERFORM EditEntityText(uEntity, 'Regione', null, GetLocale('it'));
  PERFORM EditEntityText(uEntity, 'Región', null, GetLocale('es'));

  -- Класс
  PERFORM CreateClassRegion(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('region', AddEndpoint('SELECT * FROM rest.region($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InitRegion ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitRegion()
RETURNS void
AS $$
DECLARE
  uType uuid;
BEGIN
  uType := GetType('code.region');

  PERFORM CreateRegion(null, uType, '01', 'Адыгея', 'Республика Адыгея (Адыгея)');
  PERFORM CreateRegion(null, uType, '02', 'Башкортостан', 'Республика Башкортостан');
  PERFORM CreateRegion(null, uType, '03', 'Бурятия', 'Республика Бурятия');
  PERFORM CreateRegion(null, uType, '04', 'Алтай', 'Республика Алтай');
  PERFORM CreateRegion(null, uType, '05', 'Дагестан', 'Республика Дагестан');
  PERFORM CreateRegion(null, uType, '06', 'Ингушетия', 'Республика Ингушетия');

  PERFORM CreateRegion(null, uType, '07', 'Кабардино-Балкарская Республика', 'Кабардино-Балкарская Республика');
  PERFORM CreateRegion(null, uType, '08', 'Калмыкия', 'Республика Калмыкия');
  PERFORM CreateRegion(null, uType, '09', 'Карачаево-Черкесская Республика', 'Карачаево-Черкесская Республика');
  PERFORM CreateRegion(null, uType, '10', 'Карелия', 'Республика Карелия');
  PERFORM CreateRegion(null, uType, '11', 'Коми', 'Республика Коми');
  PERFORM CreateRegion(null, uType, '12', 'Марий Эл', 'Республика Марий Эл');
  PERFORM CreateRegion(null, uType, '13', 'Мордовия', 'Республика Мордовия');
  PERFORM CreateRegion(null, uType, '14', 'Саха (Якутия)', 'Республика Саха (Якутия)');
  PERFORM CreateRegion(null, uType, '15', 'Северная Осетия - Алания', 'Республика Северная Осетия - Алания');
  PERFORM CreateRegion(null, uType, '16', 'Татарстан', 'Республика Татарстан (Татарстан)');
  PERFORM CreateRegion(null, uType, '17', 'Тыва', 'Республика Тыва');
  PERFORM CreateRegion(null, uType, '18', 'Удмуртская Республика', 'Удмуртская Республика');
  PERFORM CreateRegion(null, uType, '19', 'Хакасия', 'Республика Хакасия');
  PERFORM CreateRegion(null, uType, '20', 'Чеченская Республика', 'Чеченская Республика');
  PERFORM CreateRegion(null, uType, '21', 'Чувашская Республика - Чувашия', 'Чувашская Республика - Чувашия');

  PERFORM CreateRegion(null, uType, '22', 'Алтайский край', 'Алтайский край');
  PERFORM CreateRegion(null, uType, '23', 'Краснодарский край', 'Краснодарский край');
  PERFORM CreateRegion(null, uType, '24', 'Красноярский край', 'Красноярский край');
  PERFORM CreateRegion(null, uType, '25', 'Приморский край', 'Приморский край');
  PERFORM CreateRegion(null, uType, '26', 'Ставропольский край', 'Ставропольский край');
  PERFORM CreateRegion(null, uType, '27', 'Хабаровский край', 'Хабаровский край');

  PERFORM CreateRegion(null, uType, '28', 'Амурская область', 'Амурская область');
  PERFORM CreateRegion(null, uType, '29', 'Архангельская область', 'Архангельская область');
  PERFORM CreateRegion(null, uType, '30', 'Астраханская область', 'Астраханская область');
  PERFORM CreateRegion(null, uType, '31', 'Белгородская область', 'Белгородская область');
  PERFORM CreateRegion(null, uType, '32', 'Брянская область', 'Брянская область');
  PERFORM CreateRegion(null, uType, '33', 'Владимирская область', 'Владимирская область');
  PERFORM CreateRegion(null, uType, '34', 'Волгоградская область', 'Волгоградская область');
  PERFORM CreateRegion(null, uType, '35', 'Вологодская область', 'Вологодская область');
  PERFORM CreateRegion(null, uType, '36', 'Воронежская область', 'Воронежская область');
  PERFORM CreateRegion(null, uType, '37', 'Ивановская область', 'Ивановская область');
  PERFORM CreateRegion(null, uType, '38', 'Иркутская область', 'Иркутская область');
  PERFORM CreateRegion(null, uType, '39', 'Калининградская область', 'Калининградская область');
  PERFORM CreateRegion(null, uType, '40', 'Калужская область', 'Калужская область');
  PERFORM CreateRegion(null, uType, '41', 'Камчатский край', 'Камчатский край');
  PERFORM CreateRegion(null, uType, '42', 'Кемеровская область', 'Кемеровская область');
  PERFORM CreateRegion(null, uType, '43', 'Кировская область', 'Кировская область');
  PERFORM CreateRegion(null, uType, '44', 'Костромская область', 'Костромская область');
  PERFORM CreateRegion(null, uType, '45', 'Курганская область', 'Курганская область');
  PERFORM CreateRegion(null, uType, '46', 'Курская область', 'Курская область');
  PERFORM CreateRegion(null, uType, '47', 'Ленинградская область', 'Ленинградская область');
  PERFORM CreateRegion(null, uType, '48', 'Липецкая область', 'Липецкая область');
  PERFORM CreateRegion(null, uType, '49', 'Магаданская область', 'Магаданская область');
  PERFORM CreateRegion(null, uType, '50', 'Московская область', 'Московская область');
  PERFORM CreateRegion(null, uType, '51', 'Мурманская область', 'Мурманская область');
  PERFORM CreateRegion(null, uType, '52', 'Нижегородская область', 'Нижегородская область');
  PERFORM CreateRegion(null, uType, '53', 'Новгородская область', 'Новгородская область');
  PERFORM CreateRegion(null, uType, '54', 'Новосибирская область', 'Новосибирская область');
  PERFORM CreateRegion(null, uType, '55', 'Омская область', 'Омская область');
  PERFORM CreateRegion(null, uType, '56', 'Оренбургская область', 'Оренбургская область');
  PERFORM CreateRegion(null, uType, '57', 'Орловская область', 'Орловская область');
  PERFORM CreateRegion(null, uType, '58', 'Пензенская область', 'Пензенская область');
  PERFORM CreateRegion(null, uType, '59', 'Пермский край', 'Пермский край');
  PERFORM CreateRegion(null, uType, '60', 'Псковская область', 'Псковская область');
  PERFORM CreateRegion(null, uType, '61', 'Ростовская область', 'Ростовская область');
  PERFORM CreateRegion(null, uType, '62', 'Рязанская область', 'Рязанская область');
  PERFORM CreateRegion(null, uType, '63', 'Самарская область', 'Самарская область');
  PERFORM CreateRegion(null, uType, '64', 'Саратовская область', 'Саратовская область');
  PERFORM CreateRegion(null, uType, '65', 'Сахалинская область', 'Сахалинская область');
  PERFORM CreateRegion(null, uType, '66', 'Свердловская область', 'Свердловская область');
  PERFORM CreateRegion(null, uType, '67', 'Смоленская область', 'Смоленская область');
  PERFORM CreateRegion(null, uType, '68', 'Тамбовская область', 'Тамбовская область');
  PERFORM CreateRegion(null, uType, '69', 'Тверская область', 'Тверская область');
  PERFORM CreateRegion(null, uType, '70', 'Томская область', 'Томская область');
  PERFORM CreateRegion(null, uType, '71', 'Тульская область', 'Тульская область');
  PERFORM CreateRegion(null, uType, '72', 'Тюменская область', 'Тюменская область');
  PERFORM CreateRegion(null, uType, '73', 'Ульяновская область', 'Ульяновская область');
  PERFORM CreateRegion(null, uType, '74', 'Челябинская область', 'Челябинская область');
  PERFORM CreateRegion(null, uType, '75', 'Забайкальский край', 'Забайкальский край');
  PERFORM CreateRegion(null, uType, '76', 'Ярославская область', 'Ярославская область');

  PERFORM CreateRegion(null, uType, '77', 'Москва', 'г. Москва');
  PERFORM CreateRegion(null, uType, '78', 'Санкт-Петербург', 'Санкт-Петербург');
  PERFORM CreateRegion(null, uType, '79', 'Еврейская автономная область', 'Еврейская автономная область');

  PERFORM CreateRegion(null, uType, '83', 'Ненецкий автономный округ', 'Ненецкий автономный округ');
  PERFORM CreateRegion(null, uType, '86', 'Ханты-Мансийский автономный округ - Югра', 'Ханты-Мансийский автономный округ - Югра');
  PERFORM CreateRegion(null, uType, '87', 'Чукотский автономный округ', 'Чукотский автономный округ');
  PERFORM CreateRegion(null, uType, '89', 'Ямало-Ненецкий автономный округ', 'Ямало-Ненецкий автономный округ');

  PERFORM CreateRegion(null, uType, '99', 'Иные территории', 'Иные территории, включая город и космодром Байконур');
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
