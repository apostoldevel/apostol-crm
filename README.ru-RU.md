[![en](https://img.shields.io/badge/lang-en-green.svg)](README.md)

# Apostol CRM

**Apostol CRM**[^crm] — готовый к продакшену шаблон бэкенда, который даёт вам **[418 REST API эндпоинтов](www/docs/api.yaml)**, **[аутентификацию OAuth 2.0](https://github.com/apostoldevel/module-AuthServer#readme)**, **[движок бизнес-процессов](https://github.com/apostoldevel/db-platform/wiki/04-Workflow)**, **[WebSocket pub/sub](https://github.com/apostoldevel/module-WebSocketAPI#readme)**, **[фоновую обработку](https://github.com/apostoldevel/process-MessageServer#readme)** и **[файловое хранилище](https://github.com/apostoldevel/module-FileServer#readme)** — всё в одном бинарнике с базой данных PostgreSQL.

Построен на двух open-source фреймворках:

| Фреймворк | Роль | Что предоставляет |
|-----------|------|-------------------|
| [**A-POST-OL**](https://github.com/apostoldevel/libapostol) | C++20 сервер | HTTP/WebSocket сервер, асинхронный PostgreSQL, один `epoll` event loop — **507K RPS** |
| [**db-platform**](https://github.com/apostoldevel/db-platform) | Слой PostgreSQL | 26 PL/pgSQL модулей, 100+ таблиц, 800+ функций — REST API, аутентификация, бизнес-процессы, сущности |

Без PHP. Без Python. Без Node.js. HTTP-запросы идут напрямую из C++ в PostgreSQL — ноль промежуточных слоёв, задержка менее миллисекунды.

> **Это шаблон.** Форкните его, добавьте свои сущности, настройте бизнес-процессы — и у вас готовый продакшен-бэкенд. Всё перечисленное ниже включено из коробки.

## Что вы получаете

| Категория | Детали |
|-----------|--------|
| **Аутентификация** | OAuth 2.0 (6 типов авторизации), JWT (HS/RS/ES/PS), сессии на cookies, RBAC |
| **REST API** | 418 эндпоинтов со спецификацией [OpenAPI 3.0](www/docs/api.yaml) и [Swagger UI](https://swagger.io/tools/swagger-ui/) |
| **Сущности** | 30 бизнес-сущностей — клиенты, счета, платежи, подписки, устройства и другие |
| **Бизнес-процессы** | Машина состояний для каждой сущности: `создан → активирован ↔ отключён → удалён` с пользовательскими переходами |
| **Real-time** | WebSocket с JSON-RPC и pub/sub ([паттерн Observer](https://github.com/apostoldevel/db-platform/wiki/65-Observer-PubSub)) |
| **Фоновые процессы** | Рассылка email/SMS/push, cron-планировщик, генерация отчётов — как отдельные процессы ОС |
| **Файловое хранилище** | Виртуальная файловая система с UNIX-правами и поддержкой S3 |
| **Контроль доступа** | Трёхуровневая система прав: [ACU](https://github.com/apostoldevel/db-platform/wiki/64-Access-Control) (класс), AOU (объект), AMU (метод) |
| **Локализация** | Сообщения об ошибках и состояния бизнес-процессов на 6 языках (EN, RU, DE, FR, IT, ES) |
| **Производительность** | [507K RPS](https://github.com/apostoldevel/apostol/blob/master/doc/BENCHMARK.md) на `/ping` (90% от Nginx), 112K RPS с обращением к PostgreSQL |

## Как это работает

**Apostol CRM** объединяет два фреймворка в единый бэкенд:

```
                        ┌─────────────────────────────────────────────────┐
 HTTP/WebSocket    ──>  │  C++ Сервер (libapostol)                       │
   запрос               │                                                 │
                        │  Мастер-процесс                                 │
                        │  ├── Workers (N)     ← AppServer, AuthServer,   │
                        │  │                     FileServer, WebSocketAPI, │
                        │  │                     PGHTTP, WebServer         │
                        │  ├── Helper (1)      ← PGFetch, PGFile          │
                        │  └── Processes       ← MessageServer,           │
                        │                        TaskScheduler,            │
                        │                        ReportServer              │
                        └────────────┬────────────────────────────────────┘
                                     │ libpq async
                        ┌────────────▼────────────────────────────────────┐
                        │  PostgreSQL (db-platform)                       │
                        │                                                 │
                        │  rest.* ─> api.* ─> kernel.* ─> db.*           │
                        │  (dispatch)  (CRUD)   (логика)   (таблицы)      │
                        │                                                 │
                        │  26 модулей платформы + 30 сущностей проекта    │
                        └─────────────────────────────────────────────────┘
```

**Слой C++** обрабатывает HTTP-парсинг, TLS, пулинг соединений, WebSocket, проверку JWT и асинхронный ввод-вывод. **Слой базы данных** содержит бизнес-логику, маршрутизацию REST, контроль доступа, переходы состояний и хранение данных. Они взаимодействуют через `libpq` — один event loop, без потоков.

## Быстрый старт

### Docker (рекомендуется)

```bash
git clone --recurse-submodules https://github.com/apostoldevel/apostol-crm.git
cd apostol-crm/backend
./docker-build.sh
./docker-up.sh
```

Запускаются пять сервисов: **PostgreSQL 18** · **PgBouncer** · **Nginx** · **PgWeb** · **Backend**

| URL | Описание |
|-----|----------|
| [localhost:8080](http://localhost:8080) | Фронтенд |
| [localhost:8080/docs](http://localhost:8080/docs) | Swagger UI (418 эндпоинтов) |
| [localhost:8081](http://localhost:8081) | PgWeb — администрирование БД |

Учётные данные по умолчанию: **admin** / **admin**

```bash
./docker-down.sh           # остановить все сервисы
./docker-new-database.sh   # пересоздать том PostgreSQL (деструктивно)
```

### Сборка из исходного кода

**Требования:** Linux, GCC 12+, CMake 3.25+, PostgreSQL 12+, OpenSSL, libcurl, zlib

```bash
# Установка зависимостей (Debian/Ubuntu)
sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev \
    libpq-dev zlib1g-dev make cmake gcc g++

# Сборка
git clone --recurse-submodules https://github.com/apostoldevel/apostol-crm.git
cd apostol-crm/backend
./configure
cmake --build cmake-build-release --parallel $(nproc)
sudo cmake --install cmake-build-release
```

**Настройка базы данных:**

```bash
# 1. Настроить пароли
echo '*:*:*:kernel:kernel' >> ~/.pgpass
echo '*:*:*:admin:admin'   >> ~/.pgpass
echo '*:*:*:daemon:daemon' >> ~/.pgpass
chmod 600 ~/.pgpass

# 2. Установить search_path в postgresql.conf, затем перезапустить PostgreSQL
#    search_path = '"$user", kernel, public'

# 3. Инициализация
cd db/
./runme.sh --init
```

**Запуск:**

```bash
sudo service apostol-crm start
curl http://localhost:4977/api/v1/ping   # {"ok": true}
```

### Режим разработки

```bash
./configure --debug
cmake --build cmake-build-debug --parallel $(nproc)
mkdir -p logs
./cmake-build-debug/apostol-crm -p . -c conf/default.json
```

## Модули и процессы

Каждый модуль — это отдельный [GitHub-репозиторий](https://github.com/apostoldevel), клонируемый скриптом `./configure`:

### Workers — обработка HTTP/WebSocket запросов

| Модуль | Описание | Документация |
|--------|----------|------------|
| [AppServer](https://github.com/apostoldevel/module-AppServer) | REST API с авторизацией → диспетчеризация в PostgreSQL | [README](https://github.com/apostoldevel/module-AppServer#readme) |
| [AuthServer](https://github.com/apostoldevel/module-AuthServer) | OAuth 2.0 (6 типов авторизации), JWT, cookies, PKCE | [README](https://github.com/apostoldevel/module-AuthServer#readme) |
| [WebSocketAPI](https://github.com/apostoldevel/module-WebSocketAPI) | JSON-RPC + pub/sub через WebSocket | [README](https://github.com/apostoldevel/module-WebSocketAPI#readme) |
| [FileServer](https://github.com/apostoldevel/module-FileServer) | Раздача файлов из `db.file` с JWT-аутентификацией | [README](https://github.com/apostoldevel/module-FileServer#readme) |
| [PGHTTP](https://github.com/apostoldevel/module-PGHTTP) | HTTP → диспетчеризация в PL/pgSQL функции | [README](https://github.com/apostoldevel/module-PGHTTP#readme) |
| [WebServer](https://github.com/apostoldevel/module-WebServer) | Статические файлы, поддержка SPA, Swagger UI | [README](https://github.com/apostoldevel/module-WebServer#readme) |

### Helpers — фоновые модули в процессе helper

| Модуль | Описание |
|--------|----------|
| [PGFetch](https://github.com/apostoldevel/module-PGFetch) | LISTEN/NOTIFY → исходящие HTTP-запросы |
| [PGFile](https://github.com/apostoldevel/module-PGFile) | LISTEN/NOTIFY → синхронизация файлов (PostgreSQL ↔ файловая система) |

### Processes — независимые фоновые демоны

| Процесс | Описание |
|---------|----------|
| [MessageServer](https://github.com/apostoldevel/process-MessageServer) | Рассылка email/SMS/push через SMTP, FCM, HTTP API |
| [TaskScheduler](https://github.com/apostoldevel/process-TaskScheduler) | Выполнение заданий по расписанию из очереди `db.job` |
| [ReportServer](https://github.com/apostoldevel/process-ReportServer) | Генерация отчётов по событию LISTEN |

Нужно меньше модулей? Отключите любой в `conf/default.json`. Нужно больше? Добавьте [Replication](https://github.com/apostoldevel/process-Replication) или [StreamServer](https://github.com/apostoldevel/process-StreamServer).

## Система сущностей

Шаблон включает **30 бизнес-сущностей** с полным CRUD, REST-эндпоинтами, состояниями бизнес-процессов и обработчиками событий:

### Справочники (references)

`address` · `calendar` · `category` · `country` · `currency` · `format` · `measure` · `model` · `property` · `region` · `service`

### Документы (documents)

| Сущность | Подсущности | Назначение |
|----------|-------------|------------|
| `account` | `balance` | Финансовые счета с темпоральным отслеживанием баланса |
| `card` | | Платёжные/идентификационные карты |
| `client` | `name`, `customer`, `employee` | Базовая сущность клиента с подклассами |
| `company` | | Компании (иерархические) |
| `device` | `station`, `caster` | IoT/ГНСС устройства |
| `identity` | | Документы, удостоверяющие личность (10 типов) |
| `invoice` | | Счета с автоплатежом |
| `job` | | Запланированные задачи |
| `message` | | Доставка email/SMS/push |
| `order` | | Финансовые ордера (дебет/кредит) |
| `payment` | `cloudpayments`, `yookassa` | Обработка платежей (два шлюза) |
| `price` | | Определения цен |
| `product` | | Каталог продуктов |
| `subscription` | | Подписки на основе времени/объёма |
| `tariff` | | Тарифные планы |
| `task` | | Выполнение фоновых задач |
| `transaction` | | Записи финансовых транзакций |

Каждая сущность следует [стандартному файловому соглашению](https://github.com/apostoldevel/db-platform/wiki/71-Creating-Entity):

```
entity/object/document/myentity/
├── table.sql       # CREATE TABLE, индексы, триггеры
├── view.sql        # Представления ядра (CREATE OR REPLACE)
├── routine.sql     # Функции Create*/Edit*/Get*/Delete*
├── api.sql         # Представления и обёртки CRUD в схеме api
├── rest.sql        # REST-диспетчер
├── event.sql       # Обработчики событий
├── init.sql        # Бизнес-процесс: состояния, методы, переходы
├── create.psql     # Мастер-скрипт создания
└── update.psql     # Мастер-скрипт обновления (без table.sql и init.sql)
```

## Расширение шаблона

### Добавить новую сущность

1. Создайте директорию в `db/sql/configuration/apostol/entity/object/document/` или `.../reference/`
2. Следуйте [файловому соглашению для сущностей](https://github.com/apostoldevel/db-platform/wiki/71-Creating-Entity) — 8 SQL-файлов на сущность
3. Подключите в `create.psql` / `update.psql`
4. Запустите `./runme.sh --install` (первый раз) или `--patch` (изменения таблиц)

Подробные руководства: [Создание документа](https://github.com/apostoldevel/db-platform/wiki/72-Creating-Document) · [Создание справочника](https://github.com/apostoldevel/db-platform/wiki/73-Creating-Reference)

### Добавить модуль или процесс

1. Клонируйте из [apostoldevel](https://github.com/apostoldevel) в `src/modules/Workers/` или `src/processes/`
2. Зарегистрируйте в `Workers.hpp` / `Processes.hpp`
3. Включите в `conf/default.json`
4. Пересоберите проект

Руководства: [Создание модулей](https://github.com/apostoldevel/libapostol/wiki/Creating-Modules) · [Создание процессов](https://github.com/apostoldevel/libapostol/wiki/Creating-Processes)

### Настройка бизнес-процессов

Каждая сущность имеет машину состояний, определённую в `init.sql`. Добавляйте пользовательские состояния, методы и переходы:

```sql
PERFORM AddState(uClass, rec_type, 'approved',  'Approved');
PERFORM AddMethod(uClass, uParent, 'Approve',   'Approve document');
PERFORM AddTransition(uState_Enabled, 'approve', uState_Approved);
```

Руководство: [Настройка бизнес-процессов](https://github.com/apostoldevel/db-platform/wiki/74-Workflow-Customization)

## Структура проекта

```
backend/
├── src/
│   ├── app/main.cpp               # Точка входа (ApostolCRMApp)
│   ├── lib/libapostol/            # C++20 фреймворк (git submodule)
│   ├── modules/
│   │   ├── Workers/               # 6 модулей обработки HTTP
│   │   └── Helpers/               # 2 фоновых модуля-помощника
│   └── processes/                 # 3 фоновых процесса
├── db/sql/
│   ├── platform/                  # db-platform (26 модулей) — НЕ РЕДАКТИРОВАТЬ
│   └── configuration/apostol/     # Сущности проекта (30) — РЕДАКТИРОВАТЬ ЗДЕСЬ
├── conf/
│   ├── default.json               # Конфигурация сервера (модули, postgres, сервер)
│   └── oauth2/                    # Конфигурации провайдеров OAuth2
├── www/docs/                      # Swagger UI + api.yaml (418 эндпоинтов)
├── docker-compose.yml             # Docker-стек из 5 сервисов
├── Dockerfile                     # Многоэтапная сборка C++20
└── configure                      # Загружает модули с GitHub
```

`libapostol` является [git-субмодулем](https://github.com/apostoldevel/libapostol). Все модули, процессы и `db/sql/platform/` — это отдельные репозитории, клонируемые скриптом `./configure`.

## База данных

| Команда | Действие |
|---------|----------|
| `./runme.sh --update` | **Безопасно:** обновить только процедуры и представления |
| `./runme.sh --patch` | Обновить таблицы + процедуры + представления |
| `./runme.sh --install` | **Деструктивно:** пересоздать БД с начальными данными |
| `./runme.sh --init` | **Деструктивно:** первичная установка (создание пользователей + установка) |

Все команды выполняются из директории `db/`.

## Конфигурация

| Файл | Назначение |
|------|------------|
| `conf/default.json` | Основная конфигурация — модули, сервер, подключения PostgreSQL |
| `conf/oauth2/default.json` | Клиенты OAuth2 (web, service, android, ios) |
| `conf/oauth2/google.json` | Провайдер Google OAuth2 |
| `.env` | Окружение Docker (порты, учётные данные БД, секреты) |
| `db/sql/sets.psql` | Имя базы данных (`apostol`), кодировка, search_path |
| `db/sql/.env.psql` | Пароли БД, настройки проекта, секреты OAuth2 |

## Сигналы управления процессом

| Сигнал | Действие |
|--------|----------|
| TERM, INT | Быстрая остановка |
| QUIT | Плавная остановка |
| HUP | Перечитать конфигурацию, перезапустить workers |
| WINCH | Плавная остановка workers |

PID-файл: `/run/apostol-crm.pid`

## Экосистема

Продакшен-проекты, построенные на тех же фреймворках:

| Проект | Отрасль | Описание                                                                            | Версия |
|--------|---------|-------------------------------------------------------------------------------------|:------:|
| [**ChargeMeCar**](https://chargemecar.com/) | Электромобили | Система управления зарядными станциями с поддержкой OCPP 1.5/1.6/2.0.1 и OCPI       | v2 |
| [**Apostol ARB**](https://arb.apostol-crm.com/) | FinTech | SaaS-агрегатор арбитража на крипто-фьючерсах (Binance, Bybit, OKX, MEXC, Bitget)    | v2 |
| [**PlugMe**](https://plugme.ru) | Электромобили | Центральная система OCPP — сотни станций, тысячи владельцев EV, интеграция платежей | v1 |
| [**Ship Safety ERP**](https://ship-safety.ru) | Морская отрасль | Автоматизированная СУБ для морской безопасности (СОЛАС, Кодекс ISM)                 | v1 |
| [**CopyFrog**](https://copyfrog.ai) | ИИ | Платформа генерации изображений, рекламных текстов и маркетингового контента        | v1 |
| [**Talking to AI**](https://t.me/TalkingToAIBot) | ИИ | Telegram-чатбот для общения с искусственным интеллектом                             | v1 |
| [**DEBT-Master**](https://debt-master.ru) | Финансы | Управление взысканием задолженности за ЖКУ                                          | v1 |
| [**Campus CORS**](https://cors.campusagro.com/) | Геодезия | Система передачи ГНСС корректирующих данных с NTRIP Caster                          | v1 |

## Документация

| Ресурс | Описание |
|--------|----------|
| [Wiki libapostol](https://github.com/apostoldevel/libapostol/wiki) | C++20 фреймворк — архитектура, модули, процессы, справочник API |
| [Wiki db-platform](https://github.com/apostoldevel/db-platform/wiki) | PostgreSQL фреймворк — 52 страницы: API, сущности, бизнес-процессы, контроль доступа |
| [Getting Started](https://github.com/apostoldevel/libapostol/wiki/Getting-Started) | От пустого проекта до полноценного бэкенда |
| [Спецификация OpenAPI](www/docs/api.yaml) | 418 REST-эндпоинтов |
| `db/INDEX.md` | Обзор слоя базы данных |
| `db/CLAUDE.md` | Команды и соглашения базы данных |

## Лицензия

[MIT](LICENSE)

---

[^crm]: **Apostol CRM** — шаблон-проект построенный на фреймворках [A-POST-OL](https://github.com/apostoldevel/libapostol) (C++20) и [PostgreSQL Framework for Backend Development](https://github.com/apostoldevel/db-platform).
