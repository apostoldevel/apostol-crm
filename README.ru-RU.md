[![en](https://img.shields.io/badge/lang-en-blue.svg)](README.md)

# Apostol CRM

**Apostol CRM**[^crm] — шаблон полнофункционального бэкенда для разработки бизнес-приложений на Linux. Объединяет C++ HTTP/WebSocket-сервер с базой данных PostgreSQL, в которой реализованы REST API, аутентификация, движок состояний и бизнес-логика — всё на PL/pgSQL.

## Архитектура

```
HTTP/WebSocket-запрос
  -> Apostol Worker (C++, единый цикл событий epoll)
  -> асинхронный запрос libpq
  -> rest.* диспетчер (PL/pgSQL)
  -> api.* функции CRUD
  -> kernel.* бизнес-логика
  -> db.* таблицы
```

Проект состоит из двух слоёв:

- **Платформа** — переиспользуемые C++ модули и [PostgreSQL-фреймворк](https://github.com/apostoldevel/db-platform) (25 PL/pgSQL модулей, 100+ таблиц, 800+ функций): OAuth2, движок состояний, система сущностей, файловое хранилище, pub/sub, отчёты.
- **Конфигурация** — бизнес-логика конкретного проекта (30 сущностей, REST-эндпоинты, обработчики событий) на PL/pgSQL.

## Возможности

- OAuth 2.0 с 6 типами авторизации, JWT, авторизация через cookie
- REST API с OpenAPI 3.0 / Swagger UI (418 эндпоинтов)
- Движок состояний (конечный автомат для каждой сущности)
- Обновления в реальном времени через WebSocket (JSON-RPC + pub/sub)
- Фоновые процессы: отправка email/SMS/push, планировщик задач, генерация отчётов
- Файловое хранилище с поддержкой S3
- Ролевой контроль доступа (ACU/AOU/AMU)
- Локализованные сообщения об ошибках (EN, RU, DE, FR, IT, ES)
- Развёртывание через Docker Compose (PostgreSQL, PgBouncer, Nginx, Swagger UI)

## Быстрый старт

### Требования

- Linux (Debian/Ubuntu)
- GCC 7+ с поддержкой C++14
- CMake 3.13+
- PostgreSQL 12+ с `libpq-dev` и `postgresql-server-dev-all`
- OpenSSL, libcurl

```bash
sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev make cmake gcc g++
```

### Сборка из исходников

```bash
git clone https://github.com/apostoldevel/apostol-crm.git
cd apostol-crm/backend
./configure
cd cmake-build-release
make
sudo make install
```

### Настройка базы данных

1. Настройте пароли PostgreSQL в `~/.pgpass`:
   ```
   *:*:*:kernel:kernel
   *:*:*:admin:admin
   *:*:*:daemon:daemon
   ```

2. Укажите `search_path` в `postgresql.conf`:
   ```
   search_path = '"$user", kernel, public'
   ```

3. Инициализируйте базу данных:
   ```bash
   cd db/
   ./runme.sh --init
   ```

### Запуск

```bash
sudo service apostol-crm start
sudo service apostol-crm status
```

API доступен по адресу: [http://localhost:4977/api/v1/ping](http://localhost:4977/api/v1/ping)

Swagger UI: [http://localhost:4977/docs/](http://localhost:4977/docs/)

## Docker

```bash
./docker-build.sh        # сборка образов
./docker-up.sh           # запуск всех сервисов
./docker-down.sh         # остановка всех сервисов
./docker-new-database.sh # пересоздание тома PostgreSQL (деструктивно)
```

Сервисы: PostgreSQL 18, PgBouncer, Nginx, PgWeb (админка), Backend.

Backend: порт 8080. PgWeb: порт 8081.

## Структура проекта

```
backend/
├── src/
│   ├── app/crm.cpp            # Точка входа приложения
│   ├── lib/delphi/            # C++ фреймворк libdelphi (клонируется через ./configure)
│   ├── core/                  # apostol-core (клонируется)
│   ├── common/                # BackEnd, FetchCommon, FileCommon (клонируется)
│   ├── modules/
│   │   ├── Workers/           # Обработчики HTTP-запросов (клонируются)
│   │   │   ├── AppServer/     # REST -> PG диспетчер с авторизацией
│   │   │   ├── AuthServer/    # OAuth2 + JWT
│   │   │   ├── FileServer/    # Раздача файлов
│   │   │   ├── WebServer/     # Статические файлы + Swagger UI
│   │   │   └── WebSocketAPI/  # JSON-RPC + pub/sub
│   │   └── Helpers/           # Фоновые хелперы (клонируются)
│   │       ├── PGFetch/       # LISTEN -> исходящие HTTP-запросы
│   │       └── PGFile/        # LISTEN -> синхронизация файлов
│   └── processes/             # Фоновые процессы (клонируются)
│       ├── MessageServer/     # Отправка SMTP/FCM/API
│       ├── TaskScheduler/     # Планировщик задач
│       └── ReportServer/      # Генерация отчётов
├── db/
│   └── sql/
│       ├── platform/          # Фреймворк db-platform (клонируется)
│       └── configuration/
│           └── apostol/       # Бизнес-логика (30 сущностей)
├── conf/                      # Конфигурация сервера (INI)
├── www/docs/                  # Swagger UI + OpenAPI-спецификация
├── .docker/                   # Файлы для сборки Docker
├── docker-compose.yml
├── Dockerfile
└── configure                  # Скачивает все зависимости с GitHub
```

Все модули и процессы в `src/` — это отдельные репозитории, клонируемые через `./configure`. Директория `db/sql/platform/` также клонируется из [db-platform](https://github.com/apostoldevel/db-platform).

## Команды для базы данных

Выполняются из директории `db/`:

```bash
./runme.sh --update    # Безопасно: обновляет только функции и представления
./runme.sh --patch     # Обновляет таблицы + функции + представления
./runme.sh --install   # ДЕСТРУКТИВНО: пересоздание БД с начальными данными
./runme.sh --init      # ДЕСТРУКТИВНО: первичная настройка (создание пользователей + install)
```

## Конфигурация

| Файл | Назначение |
|------|------------|
| `conf/default.conf` | Основной конфиг сервера (модули, процессы, PostgreSQL) |
| `conf/oauth2/default.json` | Определения клиентов OAuth2 |
| `.env` | Окружение Docker (порты, учётные данные БД) |
| `db/sql/sets.psql` | Имя базы данных, кодировка, search_path |
| `db/sql/.env.psql` | Пароли БД, настройки проекта, секреты OAuth2 |

## Управление процессами

Сигналы:

| Сигнал | Действие |
|--------|----------|
| TERM, INT | Быстрое завершение |
| QUIT | Плавное завершение |
| HUP | Перезагрузка конфигурации, перезапуск воркеров |
| WINCH | Плавное завершение воркеров |

PID-файл: `/run/apostol-crm.pid`

## Документация

- [Wiki db-platform](https://github.com/apostoldevel/db-platform/wiki) — руководство по API (52 страницы)
- [OpenAPI-спецификация](www/docs/api.yaml) — 418 REST-эндпоинтов
- `db/INDEX.md` — обзор слоя базы данных
- `db/CLAUDE.md` — команды и соглашения для базы данных

## Лицензия

[MIT](LICENSE)

---

[^crm]: **Apostol CRM** — шаблон-проект построенный на фреймворках [A-POST-OL](https://github.com/apostoldevel/libapostol) (C++20) и [PostgreSQL Framework for Backend Development](https://github.com/apostoldevel/db-platform).
