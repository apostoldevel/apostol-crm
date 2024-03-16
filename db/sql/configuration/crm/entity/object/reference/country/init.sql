--------------------------------------------------------------------------------
-- Initialization --------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AddCountryEvents ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION AddCountryEvents (
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
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна создана', 'EventCountryCreate();');
    END IF;

    IF r.code = 'open' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна открыта', 'EventCountryOpen();');
    END IF;

    IF r.code = 'edit' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна изменена', 'EventCountryEdit();');
    END IF;

    IF r.code = 'save' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна сохранена', 'EventCountrySave();');
    END IF;

    IF r.code = 'enable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна доступна', 'EventCountryEnable();');
    END IF;

    IF r.code = 'disable' THEN
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна недоступна', 'EventCountryDisable();');
    END IF;

    IF r.code = 'delete' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна будет удалена', 'EventCountryDelete();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'restore' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна восстановлена', 'EventCountryRestore();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

    IF r.code = 'drop' THEN
      PERFORM AddEvent(pClass, uEvent, r.id, 'Страна будет уничтожена', 'EventCountryDrop();');
      PERFORM AddEvent(pClass, uParent, r.id, 'События класса родителя');
    END IF;

  END LOOP;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateClassCountry ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateClassCountry (
  pParent       uuid,
  pEntity       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uClass        uuid;
BEGIN
  -- Класс
  uClass := AddClass(pParent, pEntity, 'country', 'Страна', false);

  -- Тип
  PERFORM AddType(uClass, 'iso.country', 'ISO 3166', 'Список кодов по ISO 3166.');

  -- Событие
  PERFORM AddCountryEvents(uClass);

  -- Метод
  PERFORM AddDefaultMethods(uClass, ARRAY['Создана', 'Открыта', 'Закрыта', 'Удалена', 'Открыть', 'Закрыть', 'Удалить']);

  RETURN uClass;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- CreateEntityCountry ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateEntityCountry (
  pParent       uuid
)
RETURNS         uuid
AS $$
DECLARE
  uEntity       uuid;
BEGIN
  -- Сущность
  uEntity := AddEntity('country', 'Страна');

  -- Класс
  PERFORM CreateClassCountry(pParent, uEntity);

  -- API
  PERFORM RegisterRoute('country', AddEndpoint('SELECT * FROM rest.country($1, $2);'));

  RETURN uEntity;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- InitCountry -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitCountry()
RETURNS         void
AS $$
BEGIN
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Австралия', null, 'AU', 'AUS', 36);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Австрия', null, 'AT', 'AUT', 40);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Азербайджан', null, 'AZ', 'AZE', 31);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Албания', null, 'AL', 'ALB', 8);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Алжир', null, 'DZ', 'DZA', 12);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ангилья о. (GB)', null, 'AI', 'AIA', 660);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ангола', null, 'AO', 'AGO', 24);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Андорра', null, 'AD', 'AND', 20);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Антарктика', null, 'AQ', 'ATA', 10);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Антигуа и Барбуда', null, 'AG', 'ATG', 28);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Антильские о‐ва (NL)', null, 'AN', 'ANT', 530);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Аргентина', null, 'AR', 'ARG', 32);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Армения', null, 'AM', 'ARM', 51);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Аруба', null, 'AW', 'ABW', 533);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Афганистан', null, 'AF', 'AFG', 4);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Багамы', null, 'BS', 'BHS', 44);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бангладеш', null, 'BD', 'BGD', 50);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Барбадос', null, 'BB', 'BB', 52);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бахрейн', null, 'BH', 'BHR', 48);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Беларусь', null, 'BY', 'BLR', 112);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Белиз', null, 'BZ', 'BLZ', 84);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бельгия', null, 'BE', 'BEL', 56);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бенин', null, 'BJ', 'BEN', 204);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бермуды', null, 'BM', 'BMU', 60);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бове о. (NO)', null, 'BV', 'BVT', 74);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Болгария', null, 'BG', 'BGR', 100);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Боливия', null, 'BO', 'BOL', 68);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Босния и Герцеговина', null, 'BA', 'BIH', 70);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ботсвана', null, 'BW', 'BWA', 72);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бразилия', null, 'BR', 'BRA', 76);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бруней Дарассалам', null, 'BN', 'BRN', 96);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Буркина‐Фасо', null, 'BF', 'BFA', 854);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бурунди', null, 'BI', 'BDI', 108);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Бутан', null, 'BT', 'BTN', 64);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Вануату', null, 'VU', 'VUT', 548);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ватикан', null, 'VA', 'VAT', 336);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Великобритания', null, 'GB', 'GBR', 826);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Венгрия', null, 'HU', 'HUN', 348);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Венесуэла', null, 'VE', 'VEN', 862);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Виргинские о‐ва (GB)', null, 'VG', 'VGB', 92);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Виргинские о‐ва (US)', null, 'VI', 'VIR', 850);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Восточное Самоа (US)', null, 'AS', 'ASM', 16);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Восточный Тимор', null, 'TP', 'TMP', 626);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Вьетнам', null, 'VN', 'VNM', 704);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Габон', null, 'GA', 'GAB', 266);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гаити', null, 'HT', 'HTI', 332);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гайана', null, 'GY', 'GUY', 328);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гамбия', null, 'GM', 'GMB', 270);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гана', null, 'GH', 'GHA', 288);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гваделупа', null, 'GP', 'GLP', 312);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гватемала', null, 'GT', 'GTM', 320);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гвинея', null, 'GN', 'GIN', 324);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гвинея‐Бисау', null, 'GW', 'GNB', 624);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Германия', null, 'DE', 'DEU', 276);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гибралтар', null, 'GI', 'GIB', 292);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гондурас', null, 'HN', 'HND', 340);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гонконг (CN', null, 'HK', 'HKG', 344);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гренада', null, 'GD', 'GRD', 308);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гренландия (DK)', null, 'GL', 'GRL', 304);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Греция', null, 'GR', 'GRC', 300);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Грузия', null, 'GE', 'GEO', 268);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Гуам', null, 'GU', 'GUM', 316);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Дания', null, 'DK', 'DNK', 208);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Демократическая Республика Конго', null, 'CD', 'COD', 180);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Джибути', null, 'DJ', 'DJI', 262);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Доминика', null, 'DM', 'DMA', 212);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Доминиканская Республика', null, 'DO', 'DOM', 214);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Египет', null, 'EG', 'EGY', 818);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Замбия', null, 'ZM', 'ZMB', 894);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Западная Сахара', null, 'EH', 'ESH', 732);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Зимбабве', null, 'ZW', 'ZWE', 716);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Израиль', null, 'IL', 'ISR', 376);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Индия', null, 'IN', 'IND', 356);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Индонезия', null, 'ID', 'IDN', 360);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Иордания', null, 'JO', 'JOR', 400);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ирак', null, 'IQ', 'IRQ', 368);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Иран', null, 'IR', 'IRN', 364);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ирландия', null, 'IE', 'IRL', 372);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Исландия', null, 'IS', 'ISL', 352);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Испания', null, 'ES', 'ESP', 724);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Италия', null, 'IT', 'ITA', 380);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Йемен', null, 'YE', 'YEM', 887);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кабо‐Верде', null, 'CV', 'CPV', 132);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Казахстан', null, 'KZ', 'KAZ', 398);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Каймановы о‐ва (GB)', null, 'KY', 'CYM', 136);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Камбоджа', null, 'KH', 'KHM', 116);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Камерун', null, 'CM', 'CMR', 120);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Канада', null, 'CA', 'CAN', 124);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Катар', null, 'QA', 'QAT', 634);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кения', null, 'KE', 'KEN', 404);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кипр', null, 'CY', 'CYP', 196);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Киргизстан', null, 'KG', 'KGZ', 417);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кирибати', null, 'KI', 'KIR', 296);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Китай', null, 'CN', 'CHN', 156);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кокосовые (Киилинг) о‐ва (AU)', null, 'CC', 'CCK', 166);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Колумбия', null, 'CO', 'COL', 170);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Коморские о‐ва', null, 'KM', 'COM', 174);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Конго', null, 'CG', 'COG', 178);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Коста‐Рика', null, 'CR', 'CRI', 188);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кот‐д`Ивуар', null, 'CI', 'CIV', 384);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Куба', null, 'CU', 'CUB', 192);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кувейт', null, 'KW', 'KWT', 414);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Кука о‐ва (NZ)', null, 'CK', 'COK', 184);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Лаос', null, 'LA', 'LAO', 418);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Латвия', null, 'LV', 'LVA', 428);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Лесото', null, 'LS', 'LSO', 426);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Либерия', null, 'LR', 'LBR', 430);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ливан', null, 'LB', 'LBN', 422);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ливия', null, 'LY', 'LBY', 434);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Литва', null, 'LT', 'LTU', 440);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Лихтенштейн', null, 'LI', 'LIE', 438);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Люксембург', null, 'LU', 'LUX', 442);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Маврикий', null, 'MU', 'MUS', 480);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мавритания', null, 'MR', 'MRT', 478);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мадагаскар', null, 'MG', 'MDG', 450);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Майотта о. (KM)', null, 'YT', 'MYT', 175);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Макао (PT)', null, 'MO', 'MAC', 446);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Македония', null, 'MK', 'MKD', 807);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Малави', null, 'MW', 'MWI', 454);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Малайзия', null, 'MY', 'MYS', 458);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мали', null, 'ML', 'MLI', 466);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мальдивы', null, 'MV', 'MDV', 462);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мальта', null, 'MT', 'MLT', 470);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Марокко', null, 'MA', 'MAR', 504);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мартиника', null, 'MQ', 'MTQ', 474);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Маршалловы о‐ва', null, 'MH', 'MHL', 584);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мексика', null, 'MX', 'MEX', 484);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Микронезия (US)', null, 'FM', 'FSM', 583);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мозамбик', null, 'MZ', 'MOZ', 508);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Молдова', null, 'MD', 'MDA', 498);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Монако', null, 'MC', 'MCO', 492);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Монголия', null, 'MN', 'MNG', 496);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Монсеррат о. (GB)', null, 'MS', 'MSR', 500);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Мьянма', null, 'MM', 'MMR', 104);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Намибия', null, 'NA', 'NAM', 516);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Науру', null, 'NR', 'NRU', 520);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Непал', null, 'NP', 'NPL', 524);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Нигер', null, 'NE', 'NER', 562);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Нигерия', null, 'NG', 'NGA', 566);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Нидерланды', null, 'NL', 'NLD', 528);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Никарагуа', null, 'NI', 'NIC', 558);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ниуэ о. (NZ)', null, 'NU', 'NIU', 570);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Новая Зеландия', null, 'NZ', 'NZL', 554);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Новая Каледония о. (FR)', null, 'NC', 'NCL', 540);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Норвегия', null, 'NO', 'NOR', 578);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Норфолк о. (AU)', null, 'NF', 'NFK', 574);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Объединенные Арабские Эмираты', null, 'AE', 'ARE', 784);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Оман', null, 'OM', 'OMN', 512);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Пакистан', null, 'PK', 'PAK', 586);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Палау (US)', null, 'PW', 'PLW', 585);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Палестинская автономия', null, 'PS', 'PSE', 275);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Панама', null, 'PA', 'PAN', 591);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Папуа‐Новая Гвинея', null, 'PG', 'PNG', 598);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Парагвай', null, 'PY', 'PRY', 600);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Перу', null, 'PE', 'PER', 604);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Питкэрн о‐ва (GB)', null, 'PN', 'PCN', 612);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Польша', null, 'PL', 'POL', 616);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Португалия', null, 'PT', 'PRT', 620);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Пуэрто‐Рико (US)', null, 'PR', 'PRI', 630);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Реюньон о. (FR)', null, 'RE', 'REU', 638);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Рождества о. (AU)', null, 'CX', 'CXR', 162);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Россия', 'Российская Федерация', 'RU', 'RUS', 643);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Руанда', null, 'RW', 'RWA', 646);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Румыния', null, 'RO', 'ROM', 642);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сальвадор', null, 'SV', 'SLV', 222);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Самоа', null, 'WS', 'WSM', 882);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сан Марино', null, 'SM', 'SMR', 674);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сан‐Томе и Принсипи', null, 'ST', 'STP', 678);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Саудовская Аравия', null, 'SA', 'SAU', 682);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Свазиленд', null, 'SZ', 'SWZ', 748);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Свалбард и Ян Мейен о‐ва (NO)', null, 'SJ', 'SJM', 744);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Святой Елены о. (GB)', null, 'SH', 'SHN', 654);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Северная Корея (КНДР)', null, 'KP', 'PRK', 408);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Северные Марианские', null, 'MP', 'MNP', 580);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сейшелы', null, 'SC', 'SYC', 690);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сен‐Винсент и Гренадины', null, 'VC', 'VCT', 670);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сен‐Пьер и Микелон (FR)', null, 'PM', 'SPM', 666);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сенегал', null, 'SN', 'SEN', 686);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сент‐Кристофер и Невис', null, 'KN', 'KNA', 659);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сент‐Люсия', null, 'LC', 'LCA', 662);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сингапур', null, 'SG', 'SGP', 702);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сирия', null, 'SY', 'SYR', 760);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Словакия', null, 'SK', 'SVK', 703);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Словения', null, 'SI', 'SVN', 705);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Соединенные Штаты Америки', null, 'US', 'USA', 840);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Соломоновы о‐ва', null, 'SB', 'SLB', 90);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сомали', null, 'SO', 'SOM', 706);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Судан', null, 'SD', 'SDN', 736);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Суринам', null, 'SR', 'SUR', 740);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Сьерра‐Леоне', null, 'SL', 'SLE', 694);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Таджикистан', null, 'TJ', 'TJK', 762);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Таиланд', null, 'TH', 'THA', 764);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Тайвань', null, 'TW', 'TWN', 158);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Танзания', null, 'TZ', 'TZA', 834);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Теркс и Кайкос о‐ва (GB)', null, 'TC', 'TCA', 796);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Того', null, 'TG', 'TGO', 768);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Токелау о‐ва (NZ)', null, 'TK', 'TKL', 772);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Тонга', null, 'TO', 'TON', 776);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Тринидад и Тобаго', null, 'TT', 'TTO', 780);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Тувалу', null, 'TV', 'TUV', 798);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Тунис', null, 'TN', 'TUN', 788);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Туркменистан', null, 'TM', 'TKM', 795);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Турция', null, 'TR', 'TUR', 792);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Уганда', null, 'UG', 'UGA', 800);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Узбекистан', null, 'UZ', 'UZB', 860);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Украина', null, 'UA', 'UKR', 804);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Уоллис и Футунао‐ва (FR)', null, 'WF', 'WLF', 876);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Уругвай', null, 'UY', 'URY', 858);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Фарерские о‐ва (DK)', null, 'FO', 'FRO', 234);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Фиджи', null, 'FJ', 'FJI', 242);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Филиппины', null, 'PH', 'PHL', 608);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Финляндия', null, 'FI', 'FIN', 246);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Фолклендские (Мальвинские) о‐ва (GB/AR)', null, 'FK', 'FLK', 238);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Франция', null, 'FR', 'FRA', 250);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Французская Гвиана (FR)', null, 'GF', 'GUF', 254);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Французская Полинезия', null, 'PF', 'PYF', 258);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Херд и Макдональд о‐ва (AU)', null, 'HM', 'HMD', 334);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Хорватия', null, 'HR', 'HRV', 191);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Центрально‐африканская Республика', null, 'CF', 'CAF', 140);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Чад', null, 'TD', 'TCD', 148);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Чехия', null, 'CZ', 'CZE', 203);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Чили', null, 'CL', 'CHL', 152);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Швейцария', null, 'CH', 'CHE', 756);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Швеция', null, 'SE', 'SWE', 752);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Шри‐Ланка', null, 'LK', 'LKA', 144);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Эквадор', null, 'EC', 'ECU', 218);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Экваториальная Гвинея', null, 'GQ', 'GNQ', 226);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Эритрия', null, 'ER', 'ERI', 232);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Эстония', null, 'EE', 'EST', 233);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Эфиопия', null, 'ET', 'ETH', 231);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Югославия', null, 'YU', 'YUG', 891);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Южная Африка', null, 'ZA', 'ZAF', 710);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Южная Георгия и Южные Сандвичевы о‐ва', null, 'GS', 'SGS', 239);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Южная Корея (Республика Корея)', null, 'KR', 'KOR', 410);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Ямайка', null, 'JM', 'JAM', 388);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Япония', null, 'JP', 'JPN', 392);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Французские южные территории (FR)', null, 'TF', 'ATF', 260);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Британская территория Индийского океана (GB)', null, 'IO', 'IOT', 86);
  PERFORM CreateCountry(null, GetType('iso.country'), null, 'Соединенные Штаты Америки Внешние малые острова (US)', null, 'UM', 'UMI', 581);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
