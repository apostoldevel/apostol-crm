# Apostol CRM

**Apostol CRM** - это серверная часть (backend) системы управления взаимоотношениями с клиентами (CRM), исходные коды.

После установки Вы получите не только готовую к экплуатации серверную часть но и фреймворк для разработки серверной части информационных систем спроектированный специально для Web (SPA) и мобильных приложений.  

* В любом проекте на ранних стадиях, прежде чем перейти к реализации конкретных задач, сперва следует позаботиться о решении базовых задач, и авторизация пользователей далеко не самый важный из них. При выборе современных технологий, протоколов, фреймворков и инструментов разработки можно легко запутаться. В итоге, разработать систему с гибкой, надежной и продуманной архитектурой на современной технической базе, способной в дальнейшем решать задачи, которые не очевидны на ранних стадиях -  это задача не из лёгких. Но не для нас. И Apostol CRM - именно такая система.

СТРУКТУРА КАТАЛОГОВ
-
    auto/                       содержит файлы со скриптами
    cmake-modules/              содержит файлы с модулями CMake
    conf/                       содержит файлы с настройками
    db/                         содержит файлы со скриптами базы данных
    doc/                        содержит файлы с документацией
    src/                        содержит файлы с исходным кодом
    ├─app/                      содержит файлы с исходным кодом: Apostol Web Service
    ├─core/                     содержит файлы с исходным кодом: Apostol Core
    ├─lib/                      содержит файлы с исходным кодом библиотек
    | └─delphi/                 содержит файлы с исходным кодом библиотеки*: Delphi classes for C++
    └─modules/                  содержит файлы с исходным кодом дополнений (модулей)
    www/                        содержит файлы с Веб-сайтом

ОПИСАНИЕ
-

**Apostol CRM** состоит из двух частей - **платформы** и **конфигурации**.

- Платформа - это технологии и протоколы, системные службы и модули на базе которых строится конфигурация;
- Конфигурация - это бизнес логика конкретного проекта.

**Платформа** построена на базе фреймворка [Апостол](https://github.com/apostoldevel/apostol), имеет модульную конструкцию и включает в себя встроенную поддержку СУБД PostgreSQL.

Платформа состоит из следующих модулей (частей):

- [Сервера авторизации](https://github.com/apostoldevel/module-AuthServer) (OAuth 2.0);
- [Сервера приложений](https://github.com/apostoldevel/module-AppServer) (REST API);
- [Сервера сообщений](https://github.com/apostoldevel/process-MessageServer) (SMTP/FCM/API);
- [Файл сервера](https://github.com/apostoldevel/module-FileServer);
- [Сервера потоковых данных](https://github.com/apostoldevel/process-StreamServer) (UDP);
- [Веб-сервера](https://github.com/apostoldevel/module-WebServer) (HTTP);
- [WebSocket API](https://github.com/apostoldevel/module-WebSocketAPI) (WebSocket).

[Подробнее о составе платформы по этой ссылке.](./doc/REST-API-ru.md)

Платформа устанавливается на сервер из [исходных кодов](https://github.com/apostoldevel/apostol-crm) в виде системной службы под операционную систему Linux.

[База данных](https://github.com/apostoldevel/db-platform) платформы написана на языке программирования PL/pgSQL.

**Конфигурация** написана на языке программирования PL/pgSQL, используется для разработки бизнес-логики и RESTful API.

Конфигурация базируется на API платформы и дополняет её функциями необходимыми для решения задач конкретного проекта.

Проекты
-

- https://ship-safety.ru
- https://plugme.ru
- https://fenomy.com

API
-

Доступ к API **системы** предоставляется с помощью встроенного [сервера приложений](https://github.com/ufocomp/module-AppServer) (REST API) по адресу: [localhost:8080](http://localhost:8080)

СБОРКА И УСТАНОВКА
-
Для установки **системы** Вам потребуется:

Для сборки проекта Вам потребуется:

1. Компилятор C++;
1. [CMake](https://cmake.org) или интегрированная среда разработки (IDE) с поддержкой [CMake](https://cmake.org);
1. Библиотека [libpq-dev](https://www.postgresql.org/download) (libraries and headers for C language frontend development);
1. Библиотека [postgresql-server-dev-12](https://www.postgresql.org/download) (libraries and headers for C language backend development).

### Linux (Debian/Ubuntu)

Для того чтобы установить компилятор C++ и необходимые библиотеки на Ubuntu выполните:
~~~
$ sudo apt-get install build-essential libssl-dev libcurl4-openssl-dev make cmake gcc g++
~~~

###### Подробное описание установки C++, CMake, IDE и иных компонентов необходимых для сборки проекта не входит в данное руководство. 

#### PostgreSQL

Для того чтобы установить PostgreSQL воспользуйтесь инструкцией по [этой](https://www.postgresql.org/download/) ссылке.

#### База данных `crm`

Для того чтобы установить базу данных необходимо выполнить:

1. Прописать наименование базы данных в файле db/sql/sets.conf (по умолчанию: crm)
1. Прописать пароли для пользователей СУБД [libpq-pgpass](https://postgrespro.ru/docs/postgrespro/11/libpq-pgpass):
   ~~~
   $ sudo -iu postgres -H vim .pgpass
   ~~~
   ~~~
   *:*:*:kernel:kernel
   *:*:*:admin:admin
   *:*:*:daemon:daemon
   ~~~
1. Указать в файле настроек /etc/postgresql/<version>/main/postgresql.conf:
   Пути поиска схемы kernel:
   ~~~
   search_path = '"$user", kernel, public'	# schema names
   ~~~
1. Указать в файле настроек /etc/postgresql/<version>/main/pg_hba.conf:
   ~~~
   # TYPE  DATABASE        USER            ADDRESS                 METHOD
   local	all		kernel					md5
   local	all		admin					md5
   local	all		daemon					md5
    
   host	all		kernel		127.0.0.1/32		md5
   host	all		admin		127.0.0.1/32		md5
   host	all		daemon		127.0.0.1/32		md5   
   ~~~
1. Выполнить:
   ~~~
   $ cd db/
   $ ./install.sh --make
   ~~~

###### Параметр `--make` необходим для установки базы данных в первый раз. Далее установочный скрипт можно запускать или без параметров или с параметром `--install`.

Для установки **системы** (без Git) необходимо:

1. Скачать **Apostol CRM** по [ссылке](https://github.com/ufocomp/apostol-crm/archive/master.zip);
1. Распаковать;
1. Настроить `CMakeLists.txt` (по необходимости);
1. Собрать и скомпилировать (см. ниже).

Для установки **системы** с помощью Git выполните:
~~~
$ git clone https://github.com/ufocomp/apostol-crm.git
~~~

###### Сборка:
~~~
$ cd apostol-crm
$ ./configure
~~~

###### Компиляция и установка:
~~~
$ cd cmake-build-release
$ make
$ sudo make install
~~~

По умолчанию бинарный файл `crm` будет установлен в:
~~~
/usr/sbin
~~~

Файл конфигурации и необходимые для работы файлы, в зависимости от варианта установки, будут расположены в: 
~~~
/etc/crm
или
~/crm
~~~

ЗАПУСК 
-
###### Если `INSTALL_AS_ROOT` установлено в `ON`.

**`crm`** - это системная служба (демон) Linux. 
Для управления **`crm`** используйте стандартные команды управления службами.

Для запуска `crm` выполните:
~~~
$ sudo service crm start
~~~

Для проверки статуса выполните:
~~~
$ sudo service crm status
~~~

Результат должен быть **примерно** таким:
~~~
● crm.service - LSB: starts the apostol web service
   Loaded: loaded (/etc/init.d/crm; generated; vendor preset: enabled)
   Active: active (running) since Tue 2020-08-25 23:04:53 UTC; 4 days ago
     Docs: man:systemd-sysv-generator(8)
  Process: 6310 ExecStop=/etc/init.d/crm stop (code=exited, status=0/SUCCESS)
  Process: 6987 ExecStart=/etc/init.d/crm start (code=exited, status=0/SUCCESS)
    Tasks: 3 (limit: 4915)
   CGroup: /system.slice/crm.service
           ├─6999 crm: master process /usr/sbin/crm
           ├─7000 crm: worker process ("web socket api", "application server", "authorization server", "web server")
           └─7001 crm: message process ("message server")
~~~

### **Управление**.

Управлять **`crm`** можно с помощью сигналов.
Номер главного процесса по умолчанию записывается в файл `/run/crm.pid`. 
Изменить имя этого файла можно при конфигурации сборки или же в `crm.conf` секция `[daemon]` ключ `pid`. 

Главный процесс поддерживает следующие сигналы:

|Сигнал   |Действие          |
|---------|------------------|
|TERM, INT|быстрое завершение|
|QUIT     |плавное завершение|
|HUP	  |изменение конфигурации, запуск новых рабочих процессов с новой конфигурацией, плавное завершение старых рабочих процессов|
|WINCH    |плавное завершение рабочих процессов|	

Управлять рабочими процессами по отдельности не нужно. Тем не менее, они тоже поддерживают некоторые сигналы:

|Сигнал   |Действие          |
|---------|------------------|
|TERM, INT|быстрое завершение|
|QUIT	  |плавное завершение|
