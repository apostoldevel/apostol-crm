# Система

**Система** предоставляет доступ к методам **API** с помощью собственного HTTP-сервера [Апостол](https://github.com/ufocomp/apostol). 

Система состоит из двух абстрактных частей **платформы** и **конфигурации**. 
* **Платформа** - это технологии и протоколы (встроенные службы и модули) на которых строится система.
* **Конфигурация** - это бизнес логика проекта.

**Конфигурация** базируется на API платформы и дополняет её функциями необходимыми для решения задач проекта.

# API

## Общая информация
 * Базовая конечная точка (endpoint): [localhost:8080](http://localhost:8080)
 * Все конечные точки возвращают `JSON-объект`
 * Все поля, относящиеся ко времени и меткам времени, указаны в **миллисекундах**. 

## HTTP коды возврата
 * HTTP `4XX` коды возврата применимы для некорректных запросов - проблема на стороне клиента.
 * HTTP `5XX` коды возврата используются для внутренних ошибок - проблема на стороне сервера. Важно **НЕ** рассматривать это как операцию сбоя. Статус выполнения **НЕИЗВЕСТЕН** и может быть успешным.
 
## Коды ошибок
 * Любая конечная точка может вернуть ошибку.
  
**Пример ответа:**
```json
{
  "error": {
    "code": 404,
    "message": "Not Found"
  }
}
```

## Общая информация о конечных точках
 * Для `GET` конечных точек параметры должны быть отправлены в виде `строки запроса (query string)` .
 * Для `POST` конечных точек, некоторые параметры могут быть отправлены в виде `строки запроса (query string)`, а некоторые в виде `тела запроса (request body)`:
 * При отправке параметров в виде `тела запроса` допустимы следующие типы контента:
    * `application/x-www-form-urlencoded` для `query string`;
    * `multipart/form-data` для `HTML-форм`;
    * `application/json` для `JSON`.
 * Параметры могут быть отправлены в любом порядке.

## Платформа

### Конечные точки

#### Тест подключения
 
```http request
GET /api/v1/ping
```
Проверить подключение к REST API.
 
**Параметры:**
НЕТ
 
**Пример ответа:**
```json
{}
```
 
#### Проверить время сервера
```http request
GET /api/v1/time
```
Проверить подключение к REST API и получить текущее время сервера.
 
**Параметры:**
 НЕТ
  
**Пример ответа:**
```json
{
  "serverTime": 1583495795455
}
```
## Доступ к API

Доступ к API возможен только при наличии маркера доступа или цифровой подписи методом HMAC-SHA256. 

#### Маркер доступа

**Маркера доступа** (`access_token`) **ДОЛЖЕН** присутствовать в HTTP заголовке `Authorization` каждого запроса.
 
Формат:
~~~
Authorization: Bearer <access_token>
~~~

**Маркера доступа** - это `JSON Web Token` [RFC 7519](https://tools.ietf.org/html/rfc7519). 

Выдается он **сервером авторизации**, роль которого выполняет сама же система.

Пример запроса:
* **http request:**
```http request
GET /api/v1/whoami HTTP/1.1
Host: localhost:8080
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiIDogImFjY291bnRzLnNoaXAtc2FmZXR5LnJ1IiwgImF1ZCIgOiAid2ViLXNoaXAtc2FmZXR5LnJ1IiwgInN1YiIgOiAiZGZlMDViNzhhNzZiNmFkOGUwZmNiZWYyNzA2NzE3OTNiODZhYTg0OCIsICJpYXQiIDogMTU5MzUzMjExMCwgImV4cCIgOiAxNTkzNTM1NzEwfQ.NorYsi-Ht826HUFCEArVZ60_dEUmYiJYXubnTyweIMg
````

#### Цифровая подпись методом HMAC-SHA256

Вместо HTTP заголовка `Authorization` можно использовать подпись. 

Для передачи данных авторизации в виде подписи используются следующие HTTP заголовки:
  * `Session` - ключ сессии;
  * `Nonce` - данное время в миллисекундах;
  * `Signature` - подпись.

**Примеры:**

**Пример создания подписи на JavaScript (без данных в теле сообщения):**
~~~javascript
// CryptoJS - Standard JavaScript cryptography library

const body = null;

const Session = localStorage.getItem('Session'); // efa885ebde1baa991a3c798fc1141f6bec92fc90
const Secret = localStorage.getItem('Secret'); // y2WYJRE9f13g6qwFOEOe0rGM/ISlGFEEesUpQadHNd/aJL+ExKRj5E6OSQ9TuJRC

const Path = '/whoami';
const Nonce = (Date.now() * 1000).toString(); // 1589998352818000
const Body = JSON.stringify(body); // if body === null then Body = "null" <-- string  

const sigData = `${Path}${Nonce}${Body}`; // /whoami1589998352818000null

const Signature = CryptoJS.HmacSHA256(sigData, Secret).toString(); // 91609292e250fc30c48c2ad387d1121c703853fa88ce027e6ba0efe1fcb50ba1

let headers = new Headers();

headers.append('Session', Session);
headers.append('Nonce', Nonce);
headers.append('Signature', Signature);
headers.append('Content-Type', 'application/json');

const init = {
    method: 'POST',
    headers: headers,
    body: Body,
    mode: "cors"
};

const apiPath = `/api/v1${Path}`;

fetch(apiPath, init)
    .then((response) => {
        return response.json();
    })
    .then((json) => {
        console.log(json);
    })
    .catch((e) => {
        console.log(e.message);
});
~~~
* **openssl command:**
```shell script
echo -n "/whoami1589998352818000null" | \
openssl sha256 -hmac "y2WYJRE9f13g6qwFOEOe0rGM/ISlGFEEesUpQadHNd/aJL+ExKRj5E6OSQ9TuJRC"
(stdin)= 91609292e250fc30c48c2ad387d1121c703853fa88ce027e6ba0efe1fcb50ba1
```
* **curl command:**
```curl
curl -X POST \
     -H "Session: efa885ebde1baa991a3c798fc1141f6bec92fc90" \
     -H "Nonce: 1589998352818000" \
     -H "Signature: 91609292e250fc30c48c2ad387d1121c703853fa88ce027e6ba0efe1fcb50ba1" \
     http://localhost:8080/api/v1/whoami
````     
* **http request:**
```http request
POST /api/v1/whoami HTTP/1.1
Host: localhost:8080
Session: efa885ebde1baa991a3c798fc1141f6bec92fc90
Nonce: 1589998352818000
Signature: 91609292e250fc30c48c2ad387d1121c703853fa88ce027e6ba0efe1fcb50ba1
````
  
**Пример создания подписи на JavaScript (с данными в теле сообщения):**
~~~javascript
// CryptoJS - Standard JavaScript cryptography library

const body = {
  classcode : 'client',
  statecode : 'enabled',
  actioncode: 'invite'
};

const Session = localStorage.getItem('Session'); // efa885ebde1baa991a3c798fc1141f6bec92fc90
const Secret = localStorage.getItem('Secret'); // y2WYJRE9f13g6qwFOEOe0rGM/ISlGFEEesUpQadHNd/aJL+ExKRj5E6OSQ9TuJRC

const Path = '/method/get';
const Nonce = (Date.now() * 1000).toString(); // 1589998352902000
const Body = JSON.stringify(body); // <-- JSON string  

const sigData = `${Path}${Nonce}${Body}`; // /method/get1589998352902000{"classcode":"client","statecode":"enabled","actioncode":"invite"}

const Signature = CryptoJS.HmacSHA256(sigData, Secret).toString(); // 2b2bf5188ea40dfe8207efec56956b6170bdbc2f0ab0bffd8b50acd60979b09b

let headers = new Headers();

headers.append('Session', Session);
headers.append('Nonce', Nonce);
headers.append('Signature', Signature);
headers.append('Content-Type', 'application/json');

const init = {
    method: 'POST',
    headers: headers,
    body: Body,
    mode: "cors"
};

const apiPath = `/api/v1${Path}`;

fetch(apiPath, init)
    .then((response) => {
        return response.json();
    })
    .then((json) => {
        console.log(json);
    })
    .catch((e) => {
        console.log(e.message);
});
~~~
* **openssl command:**
```shell script
echo -n "/method/get1589998352902000{\"classcode\":\"client\",\"statecode\":\"enabled\",\"actioncode\":\"invite\"}" | \
openssl sha256 -hmac "y2WYJRE9f13g6qwFOEOe0rGM/ISlGFEEesUpQadHNd/aJL+ExKRj5E6OSQ9TuJRC"
(stdin)= 2b2bf5188ea40dfe8207efec56956b6170bdbc2f0ab0bffd8b50acd60979b09b
````
* **curl command:**
```curl
curl -X POST \
     -H "Session: efa885ebde1baa991a3c798fc1141f6bec92fc90" \
     -H "Nonce: 1589998352902000" \
     -H "Signature: 2b2bf5188ea40dfe8207efec56956b6170bdbc2f0ab0bffd8b50acd60979b09b" \
     -d "{\"classcode\":\"client\",\"statecode\":\"enabled\",\"actioncode\":\"invite\"}" \
     http://localhost:8080/api/v1/method/get
````
* **http request:**
```http request
POST /api/v1/method/get HTTP/1.1
Host: localhost:8080
Session: efa885ebde1baa991a3c798fc1141f6bec92fc90
Nonce: 1589998352902000
Signature: 2b2bf5188ea40dfe8207efec56956b6170bdbc2f0ab0bffd8b50acd60979b09b

{"classcode":"client","statecode":"enabled","actioncode":"invite"}
````

## Сервер авторизации

Встроенный в систему сервер авторизации разработан на основе спецификации **OAuth 2.0** [RFC 6749](https://tools.ietf.org/html/rfc6749) и расширении **OpenID Connect**.
 
### Аутентификация и авторизация

#### Использование протокола OAuth 2.0 для авторизации пользователя

Протокол определяет четыре роли:

 * Владелец ресурса (`resource owner`) – Пользователь системы (физическое лицо);
 * Клиент (`client`) – Приложение, которое запрашивает доступ к защищаемому ресурсу от имени его владельца;
 * Сервер авторизации (`authorization server`) – сервер, который выпускает для клиента маркеры идентификации с разрешениями от владельца ресурса, а также маркеры доступа, позволяющие получать доступ к данным;
 * Поставщик ресурса (`resource server`) – сервер, обеспечивающий доступ к защищаемому ресурсу на основе проверки маркеров идентификации и маркеров доступа (например, к идентификационным данным пользователя).

В рамках данной системы `authorization server` и `resource server` - это один и тот же сервер.

Для взаимодействия `Клиента` с `Сервером` необходимо получить идентификатор (`client_id`) и секрет (`client_secret`).

Взаимодействие происходит через `RESTful` API описанное в спецификации [RFC 6749](https://tools.ietf.org/html/rfc6749).

#### Использование OpenID Connect для аутентификации пользователя

В общем виде схема аутентификация с использованием OpenID Connect выглядит следующим образом:

 * **Клиент** (`client`) готовит запрос на аутентификацию пользователя с необходимыми параметрами;
 * **Клиент** (`client`) отправляет `GET` запрос на аутентификацию в адрес сервера авторизации;
 * **Сервер авторизации** (`authorization server`) аутентифицирует пользователя (пользователь вводит логин и пароль);
 * **Сервер авторизации** (`authorization server`) получает согласие пользователя на проведение аутентификации в данной системе;
 * **Сервер авторизации** (`authorization server`) перенаправляет пользователя обратно **Клиенту** и передает код авторизации;
 * **Клиент** (`client`) отправляет `POST` запрос с использованием кода авторизации на получения маркера идентификации;
 * **Клиент** (`client`) получает ответ, содержащий необходимый маркер идентификации (меняет код авторизации на маркер доступа);
 * **Клиент** (`client`) проводит проверку маркера идентификации и извлекает из маркера идентификатор пользователя.

Далее детально будут рассмотрены формируемые **Клиентом** запросы и ответы от **Сервера авторизации**.

#### Конечные точки сервера авторизации:

Для авторизации:
```http request
GET /oauth2/authorize
```
Для получения маркера доступа:
```http request
POST /oauth2/token
```
#### Разрешение на авторизацию

Протокол **OAuth 2** определяет четыре разных типа **разрешения на авторизацию**, каждый из которых полезен в определённых ситуациях:

 1. **Код авторизации** (`Authorization Code`): используется с серверными приложениями (server-side applications).
 1. **Неявный** (`Implicit`): используется мобильными или веб-приложениями (JavaScript), приложениями работающими на устройстве пользователя.
 1. **Учётные данные владельца ресурса** (`Resource Owner Password Credentials`): используются доверенными приложениями, например приложениями, которые являются частью самого сервера.
 1. **Учётные данные клиента** (`Client Credentials`): используются при доступе клиента (приложения) к API без авторизации пользователя.

##### Тип разрешения на авторизацию: Код авторизации

* Код авторизации является одним из наиболее распространённых типов разрешения на авторизацию, поскольку он хорошо подходит для серверных приложений, где исходный код приложения и секрет клиента не доступны посторонним. Процесс в данном случае строится на перенаправлении (redirection), что означает, что приложение должно быть в состоянии взаимодействовать с пользовательским агентом (user-agent), например, веб-браузером, и получать коды авторизации API, перенаправляемые через пользовательский агент.

**Параметры запроса:**

Поле | Значение | Описание
------------ | :------------: | ------------
client_id | `client_id` | **Обязательный**. Идентификатор клиента (приложения).
redirect_uri | `redirect_uri` | **Обязательный**. URI, на который сервер авторизации перенаправит агента пользователя (браузер) и код авторизации.
response_type | code | **Обязательный**. Указывает на то, что приложение запрашивает доступ с помощью кода авторизации.
scope | `scope` | **Рекомендуемый**. Список областей, разделенных пробелами, которые определяют ресурсы, к которым ваше приложение может получить доступ от имени пользователя.
access_type | `access_type` | **Рекомендуемый**. Указывает, может ли ваше приложение обновлять маркеры доступа, когда пользователь отсутствует в браузере. Допустимые значения параметров: online (по умолчанию) и offline. 
state | `state` | **Рекомендуемый**. Набор случайных символов которые будут возвращены сервером клиенту (используется для защиты от повторных запросов).

**Пример зпроса:**
```http request
GET /oauth2/authorize?client_id=web-service.ru&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcode&scope=api&response_type=code&access_type=online&state=c2FmZXR HTTP/1.1
Host: localhost:8080
```

```
http://localhost:8080/oauth2/authorize?
  client_id=web-service.ru&
  redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcode&
  response_type=code&
  access_type=online&
  scope=api&
  state=c2FmZXR
```

Если в ходе аутентификации не возникло ошибок, то сервер авторизации перенаправит пользователя по ссылке, указанной в `redirect_uri`, а также вернёт два обязательных параметра:
 * code – Код авторизации;
 * state – Значение параметра `state`, которое был получено в запросе на аутентификацию;

**Клиент** должен провести сравнение отправленного и полученного параметра `state`.

**Ответ с кодом авторизации:**
```
http://localhost:8080/oauth2/code?code=b%2F8NpjbB4eLaukGr68tE7maTCeBISO%2FC7hWxKGuKb8I4Ysc7uw8a2MRUMWnO3Nzt
``` 
* Обратите внимание, на то что код (`b/8NpjbB4eLaukGr68tE7maTCeBISO/C7hWxKGuKb8I4Ysc7uw8a2MRUMWnO3Nzt`) закодирован алгоритмом [URL encode](https://www.urlencoder.org/) и его нужно будет декодировать алгоритмом [URL Decode](https://www.urldecoder.org/). 

Если в ходе аутентификации возникла ошибка, то сервер авторизации перенаправит пользователя по ссылке, указанной в `redirect_uri` с информацией об ошибке:
```
http://localhost:8080/oauth2/code?code=403&error=access_denied&error_description=Access%20denied.
``` 
 
Для обмена код авторизации на маркер доступа **Клиент** должен сформировать запрос методом `POST`.

**Параметры запроса** (Все значения обязательны): 

Поле | Значение | Описание
------------ | :------------: | ------------
client_id | `client_id` | Идентификатор клиента.
client_secret | `client_secret` | Секрет клиента.
grant_type | authorization_code | Как определено в [спецификации](https://tools.ietf.org/html/rfc6749#section-4.1.3) OAuth 2.0, это поле должно содержать значение authorization_code.
code | `code` | Код авторизации, возвращенный из первоначального запроса.
redirect_uri | `redirect_uri` | URI переадресации (должен совпадать с `redirect_uri` из первоначального запроса). 

* Согласно [спецификации](https://tools.ietf.org/html/rfc6749#section-2.3.1) OAuth 2.0, параметры авторизации клиента (`client_id` и `client_secret`) могут быть переданы как в теле запроса так и в HTTP заголовке `Authorization` (HTTP Basic authentication).

```
Authorization: Basic d2ViLXNlcnZpY2UucnU6Y2xpZW50IHNlY3JldA==   
```

В ответ на запрос сервер авторизации, вернет объект JSON, который содержит маркер краткосрочного доступа и маркер обновления.

**Ответ содержит следующие поля:**

Поле | Тип | Описание
------------ | ------------ | ------------
access_token | STRING | Маркер краткосрочного доступа (сроком действия 1 час).
expires_in | INTEGER | Оставшееся время жизни маркера доступа в секундах.
token_type | STRING | Тип возвращаемого маркера. Значение всегда будет Bearer.
session | STRING | Идентификатор сессии пользователя.
refresh_token | STRING | * Маркер который вы можете использовать для получения нового маркер доступа.
id_token | STRING | * Маркер пользователя.

* Обратите внимание, что маркер обновления возвращается только в том случае, если ваше приложение в первоначальном запросе к серверу авторизации, установило в `access_type` значение: offline.
* Обратите внимание, что маркер пользователя возвращается только в том случае, если ваше приложение в первоначальном запросе к серверу авторизации, установило в `scope` одно из значений: openid, profile или email.

**Пример зпроса:**

```http request
POST http://localhost:8080/oauth2/token
Content-Type: application/x-www-form-urlencoded
 
client_id=web-service.ru&
client_secret=client%20secret&
grant_type=authorization_code&
code=b%2F8NpjbB4eLaukGr68tE7maTCeBISO%2FC7hWxKGuKb8I4Ysc7uw8a2MRUMWnO3Nzt&
redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcode
```
###### * Хоть это и не определено спецификацией, но сервер авторизации примет запрос и в формате JSON (Content-Type: `application/json`) 

**Пример ответа**:

```json
{
  "access_token" : "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiIDogImFjY291bnRzLnNoaXAtc2FmZXR5LnJ1IiwgImF1ZCIgOiAid2ViLXNoaXAtc2FmZXR5LnJ1IiwgInN1YiIgOiAiZGZlMDViNzhhNzZiNmFkOGUwZmNiZWYyNzA2NzE3OTNiODZhYTg0OCIsICJpYXQiIDogMTU5MzUzMjExMCwgImV4cCIgOiAxNTkzNTM1NzEwfQ.NorYsi-Ht826HUFCEArVZ60_dEUmYiJYXubnTyweIMg",
  "token_type" : "Bearer",
  "expires_in" : 3600,
  "session" : "dfe05b78a76b6ad8e0fcbef270671793b86aa848"
}
```

#### Тип разрешения на авторизацию: Неявный

* Неявный тип разрешения на авторизацию используется мобильными и веб-приложениями (приложениями, которые работают в веб-браузере - JavaScript), где конфиденциальность секрета клиента не может быть гарантирована. Неявный тип разрешения также основан на перенаправлении пользовательского агента, при этом маркер доступа передаётся пользовательскому агенту для дальнейшей передачи приложению. Это, в свою очередь, делает маркер доступным пользователю и другим приложениям на устройстве пользователя. Также при этом типе разрешения на авторизацию не осуществляется аутентификация подлинности приложения, а сам процесс полагается на URI перенаправления (зарегистрированном ранее в сервере авторизации).

* Неявный тип разрешения на авторизацию не поддерживает маркеры обновления (`refresh_token`) и маркера пользователя (`id_token`).

**Параметры запроса:**

Поле | Значение | Описание
------------ | :------------: | ------------
client_id | `client_id` | **Обязательный**. Идентификатор клиента (приложения).
redirect_uri | `redirect_uri` | **Обязательный**. URI, на который сервер авторизации перенаправит агента пользователя (браузер) и маркер доступа.
response_type | token | **Обязательный**. Приложения JavaScript должны установить значение параметра в token. Это значение указывает серверу авторизации возвращать маркер доступа в виде пары name = value в идентификаторе фрагмента URI (#), на который перенаправляется пользователь после завершения процесса авторизации.
scope | `scope` | **Рекомендуемый**. Список областей, разделенных пробелами, которые определяют ресурсы, к которым ваше приложение может получить доступ от имени пользователя.
state | `state` | **Рекомендуемый**. Набор случайных символов которые будут возвращены сервером клиенту (используется для защиты от повторных запросов).

**Пример зпроса:**
```http request
GET /oauth2/authorize?client_id=web-service.ru&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcallback&scope=api&response_type=token&state=c2FmZXR HTTP/1.1
Host: localhost:8080
```

```
http://localhost:8080/oauth2/authorize?
  client_id=web-service.ru&
  redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Foauth2%2Fcallback&
  response_type=token&
  scope=api&
  state=c2FmZXR
```

Маркер доступа или сообщение об ошибке возвращаются во фрагменте хэша URI перенаправления, как показано ниже:

**Ответ с маркером доступа:**
```
http://localhost:8080/callback#token_type=Bearer&expires_in=3600&session=dfe05b78a76b6ad8e0fcbef270671793b86aa848&access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiIDogImFjY291bnRzLnNoaXAtc2FmZXR5LnJ1IiwgImF1ZCIgOiAid2ViLXNoaXAtc2FmZXR5LnJ1IiwgInN1YiIgOiAiZGZlMDViNzhhNzZiNmFkOGUwZmNiZWYyNzA2NzE3OTNiODZhYTg0OCIsICJpYXQiIDogMTU5MzUzMjExMCwgImV4cCIgOiAxNTkzNTM1NzEwfQ.NorYsi-Ht826HUFCEArVZ60_dEUmYiJYXubnTyweIMg
```
* В дополнение к параметру `access_token` строка фрагмента также содержит параметр `token_type`, который всегда имеет значение Bearer, и параметр `expires_in`, который указывает время жизни маркера в секундах. Если параметр `state` был указан в запросе маркера доступа, его значение также включается в ответ.

* URI перенаправления, в данном случае это `http://localhost:8080/callback/index.html` должен указывать на веб-страницу, которая содержит скрипт для извлечения маркера доступа из URI перенаправления. 

**Ответ с ошибкой:**
```
http://localhost:8080/callback#code=403&error=access_denied&error_description=Access%20denied.
```

###### Сервер авторизации поддерживает гибридный режим типов разрешения. Если в параметре `response_type` указать, через пробел, оба значения `code token`, то сервер авторизации вернет в одном запросе и код авторизации и маркер доступа.

#### Тип разрешения на авторизацию: учётные данные владельца ресурса

* При этом типе разрешения на авторизацию пользователь предоставляет приложению напрямую свои авторизационные данные в сервисе (имя пользователя и пароль). Приложение, в свою очередь, использует полученные учётные данные пользователя для получения маркера доступа от сервиса. Этот тип разрешения на авторизацию должен использоваться только в том случае, когда другие варианты не доступны. Кроме того, этот тип разрешения стоит использовать только в случае, когда приложение пользуется доверием пользователя (например, является частью самого сервиса, или операционной системы пользователя).

После того, как пользователь передаст свои учётные данные приложению, приложение запросит маркер доступа у авторизационного сервера методом `POST`.
 
**Параметры запроса:**

Поле | Значение | Описание
------------ | :------------: | ------------
client_id | `client_id` | **Обязательный**. Идентификатор клиента.
client_secret | `client_secret` | **Обязательный**. Секрет клиента.
grant_type | password | **Обязательный**. Как определено в [спецификации](https://tools.ietf.org/html/rfc6749#section-4.3.1) OAuth 2.0, это поле должно содержать значение password.
username | `username` | **Обязательный**. Логин пользователя.
password | `password` | **Обязательный**. Пароль пользователя.
scope | `scope` | **Рекомендуемый**. Список областей, разделенных пробелами, которые определяют ресурсы, к которым ваше приложение может получить доступ от имени пользователя.

* Согласно [спецификации](https://tools.ietf.org/html/rfc6749#section-2.3.1) OAuth 2.0, параметры авторизации клиента (`client_id` и `client_secret`) могут быть переданы как в теле запроса так и в HTTP заголовке `Authorization` (HTTP Basic authentication).

```
Authorization: Basic d2ViLXNlcnZpY2UucnU6Y2xpZW50IHNlY3JldA==   
```

В ответ на запрос сервер авторизации, вернет объект JSON, который содержит маркер краткосрочного доступа и маркер обновления.

**Ответ содержит следующие поля:**

Поле | Тип | Описание
------------ | ------------ | ------------
access_token | STRING | Маркер краткосрочного доступа (сроком действия 1 час).
expires_in | INTEGER | Оставшееся время жизни маркера доступа в секундах.
token_type | STRING | Тип возвращаемого маркера. Значение всегда будет Bearer.
session | STRING | Идентификатор сессии пользователя.
refresh_token | STRING | Маркер который вы можете использовать для получения нового маркер доступа.
id_token | STRING | * Маркер пользователя.

* Обратите внимание, что маркер пользователя возвращается только в том случае, если ваше приложение в запросе к серверу авторизации, установило в `scope` одно из значений: openid, profile или email.

**Пример зпроса:**

```http request
POST http://localhost:8080/oauth2/token
Content-Type: application/x-www-form-urlencoded
 
client_id=web-service.ru&
client_secret=client%20secret&
grant_type=password&
username=admin&
password=admin
```
###### * Хоть это и не определено спецификацией, но сервер авторизации примет запрос и в формате JSON (Content-Type: `application/json`) 

Если учётные данные и клиента и пользователя корректны, сервер авторизации вернёт маркер доступа для приложения.

#### Тип разрешения на авторизацию: Учётные данные клиента

* Тип разрешения на авторизацию с использованием учётных данных клиента позволяет приложению осуществлять доступ к своему собственному аккаунту сервиса. Это может быть полезно, например, когда приложение хочет обновить собственную регистрационную информацию на сервисе или URI перенаправления, или же осуществить доступ к другой информации, хранимой в аккаунте приложения на сервисе, через API.

**Параметры запроса:**

Поле | Значение | Описание
------------ | :------------: | ------------
client_id | `client_id` | **Обязательный**. Идентификатор клиента.
client_secret | `client_secret` | **Обязательный**. Секрет клиента.
grant_type | client_credentials | **Обязательный**. Как определено в [спецификации](https://tools.ietf.org/html/rfc6749#section-4.4.2) OAuth 2.0, это поле должно содержать значение client_credentials.
scope | `scope` | **Рекомендуемый**. Список областей, разделенных пробелами, которые определяют ресурсы, к которым ваше приложение может получить доступ от имени пользователя.

* Согласно [спецификации](https://tools.ietf.org/html/rfc6749#section-2.3.1) OAuth 2.0, параметры авторизации клиента (`client_id` и `client_secret`) могут быть переданы как в теле запроса так и в HTTP заголовке `Authorization` (HTTP Basic authentication).

```
Authorization: Basic d2ViLXNlcnZpY2UucnU6Y2xpZW50IHNlY3JldA==   
```

В ответ на запрос сервер авторизации, вернет объект JSON, который содержит маркер краткосрочного доступа и маркер обновления.

**Ответ содержит следующие поля:**

Поле | Тип | Описание
------------ | ------------ | ------------
access_token | STRING | Маркер доступа (сроком действия 1 день).
expires_in | INTEGER | Оставшееся время жизни маркера доступа в секундах.
token_type | STRING | Тип возвращаемого маркера. Значение всегда будет Bearer.
session | STRING | Идентификатор сессии пользователя.
refresh_token | STRING | Маркер который вы можете использовать для получения нового маркер доступа.
id_token | STRING | * Маркер пользователя.

* Обратите внимание, что маркер пользователя возвращается только в том случае, если ваше приложение в запросе к серверу авторизации, установило в `scope` одно из значений: openid, profile или email.

**Пример зпроса:**

```http request
POST http://localhost:8080/oauth2/token
Content-Type: application/x-www-form-urlencoded
 
client_id=web-service.ru&
client_secret=client%20secret&
grant_type=client_credentials
```
###### * Хоть это и не определено спецификацией, но сервер авторизации примет запрос и в формате JSON (Content-Type: `application/json`) 

Если учётные данные клиента корректны, сервер авторизации вернёт маркер доступа для приложения.

## API платформы

### Вход в систему

```http request
POST /api/v1/sign/in
```
Вход в систему по предоставленным данным от пользователя.

* Обратите внимание, что наличие маркера доступа (пользователя) свидетельствует о том, что вход в систему уже был осуществлён.    

* Данный метод вызывается сервером авторизации при входе в систему. 

* Используйте этот метод только при подключении к системе через **WebSocket**.   

**Параметры:**

Поле | Тип | Описание
------------ | ------------ | ------------
username | STRING | **Вариативный**. Имя пользователя (`login`).
phone | STRING | **Вариативный**. Телефон.
email | STRING | **Вариативный**. Электронный адрес.
password | STRING | **Вариативный**. Пароль.
hash | STRING | **Вариативный**. Хеш SHA1 от секретного кода пользователя. Используется как альтернативный вариант входа систему по паре логин и пароль.
agent | STRING | **Игнорируется**. Агент пользователя (браузер). Значение проставляется системой.
host | STRING | **Игнорируется**. IP адрес. Значение проставляется системой.
  
**Варианты:**
 - `<username>` `<password>`
 - `<phone>` `<password>`
 - `<email>` `<password>`
 - `<hash>`
  
**Описание ответа:**

Поле | Тип | Описание
------------ | ------------ | ------------
session | STRING | Код сессии.
code | STRING | Код авторизации для получения маркера доступа по протоколу OAuth 2.0.
secret | STRING | Секретный ключ (не путать с секретный кодом пользователя) для подписи методом HMAC-SHA256.
  
**Пример:**

Запрос:
```http request
POST /api/v1/sign/in HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{"username": "admin", "password": "admin"}
```

Ответ (положительный):
```json
{
  "session":"149d2ae6fa3f82eda21f7dba21824f199d508343",
  "code":"0s4mI+o6tKbubsOirzgxl24/SVoWI8L3ruJYUz/J0+SjbnW12oF9kVe1B642Uw8P",
  "secret":"pkPm5zmHKj04Xr/NH1nKr6ZEUqOfyacC79HLFIQTrBgA6ApbgBvGiJlMBy4XBApt"
}
```

Ответ (отрицательный):
```json
{"error": {"code": 401, "message": "Вход в систему невозможен. Проверьте правильность имени пользователя и повторите ввод пароля."}}
```

### Регистрация

```http request
POST /api/v1/sign/up
```
Регистрация нового пользователя в системе.

* Обратите внимание, что наличие маркера доступа (пользователя) свидетельствует о том, что пользователь уже зарегистрирован.    

* Данный метод вызывается сервером авторизации при входе в систему под новым пользователем. 

* Используйте этот метод только при подключении к системе через **WebSocket**.   

**Параметры:**

Имя | Тип | Значение | Описание
------------ | ------------| ------------ |------------
type | STRING | entity, physical, individual | Тип пользователя.
username | STRING | | Имя пользователя (login)/ИНН.
password | STRING | Пароль.
name | JSON | | Полное наименование компании/Ф.И.О.
phone | STRING | | Телефон.
email | STRING | | Электронный адрес.
info | JSON  | | Дополнительная информация.
description | STRING | Описание.

**Формат `name`:**

Ключ | Тип | Описание
------------ | ------------ | ------------
name | STRING | Полное наименование организации/Ф.И.О одной строкой
short | STRING | Краткое наименование организации
first | STRING | Имя
last | STRING | Фамилия
middle | STRING | Отчество

Группы:
 - `<name>` `[<short>]`
 - `<first>` `<last>` `[<middle>]` `[<short>]`

**Формат `info`:** произвольный.

**Описание ответа:**

Поле | Тип | Описание
------------ | ------------ | ------------
id | NUMERIC | Идентификатор записи
result | BOOL | Результат
message | STRING | Сообщение об ошибке
  
**Пример:**

Запрос:
```http request
POST /api/v1/sign/up HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{"type":"physical","username":"ivan","password":"Passw0rd","name":{"name":"Иванов Иван Иванович","short":"Иванов Иван","first":"Иван","last":"Иванов","middle":"Иванович"},"phone":"+79001234567","email":"ivan@mail.ru"}
```

Ответ (положительный):
```json
{"id":2,"result":true,"message":"Успешно."}
``` 
 
Ответ (отрицательный):
```json
{"id":null,"result":false,"message":"Учётная запись \"ivan\" уже существует."}
``` 
 
### Кто я?
```http request
POST /api/v1/whoami
```
Получить информацию об авторизованном пользователе.

**Параметры:**
 НЕТ
  
**Пример ответа:**
```json
{
  "id": 2,
  "userid": 1009,
  "username": "ivan",
  "fullname": "Иванов Иван Иванович",
  "phone": "+79001234567",
  "email": "ivan@mail.ru",
  "session_userid": 1009,
  "session_username": "ivan",
  "session_fullname": "Иванов Иван Иванович",
  "area": 100000000015,
  "area_code": "root",
  "area_name": "Корень",
  "interface": 100000000010,
  "interface_sid": "I:1:0:0",
  "interface_name": "Все"
}
```

### Текущие значения
```http request
POST /api/v1/current/<who>
```
Получить информацию о текущих значениях.

Где `<who>`:

- `session` (сессия);
- `user` (пользователь);
- `userid` (идентификатор пользователя);
- `username` (login пользователя);
- `area` (зона);
- `interface` (интерфейс);
- `language` (язык);
- `operdate` (дата операционного дня).
 
**Параметры:**
 НЕТ
  
## Язык
### Список языков
```http request
POST /api/v1/language
```
Получить список доступных языков.

**Параметры:**
 НЕТ
  
### Текущий язык
```http request
POST /api/v1/current/language
```
Получить идентификатор выбранного (текущего) языка.

**Параметры:**
 НЕТ
  
### Установить язык
```http request
POST /api/v1/language/set
```
Установить язык. 

**Параметры:**

Имя | Тип | Значение | Описание
------------ | ------------ | ------------ |------------
id | NUMERIC |  | Идентификатор
code | STRING | en, ru | Код

Группы:
 - `<id>`
 - `<code>`
  
## Объект
### Общие параметры

 * Для конечных точек возвращающих данные **ОБЪЕКТА** в виде списка `/list` применимо единное правило и следующее параметры:

Имя | Тип | Значение | Описание
------------ | ------------ | ------------ | ------------
fields | JSON | Массив строк | Список полей. Если не указан, вернёт все доступные поля. 
search | JSON | Массив объектов | Условия для отбора данных. 
filter | JSON | Объект | Фильтр для отбора данных в виде пары ключ/значение. В качестве ключа указывается имя поля. `filter` является краткой формой `search`. 
reclimit | INTEGER | Число | Возвращает не больше заданного числа строк (может быть меньше, если сам запрос выдал меньшее количество строк).
recoffset | INTEGER | Число | Пропускает указанное число строк в запросе.
orderby | JSON | Массив строк | Порядок сортировки (список полей). Допустимо указание `ASC` и `DESC` (`name DESC`) 

**Расшифровка параметра `search`**:

Ключ | Тип | Обязательный | Описание
------------ | ------------ | ------------ | ------------
condition | STRING | НЕТ | Условие. Может принимать только два значения `AND` (по умолчанию) или `OR`. 
field | STRING | ДА | Наименование поля, к которому применяется условие. 
compare | STRING | НЕТ | Сравнение. Может принимать только одно из значений: (`EQL`, `NEQ`, `LSS`, `LEQ`, `GTR`, `GEQ`, `GIN`, `LKE`, `ISN`, `INN`).
value | STRING | ДА/НЕТ | Искомое значение. 
valarr | JSON | ДА/НЕТ | Искомые значения в виде массива. Если указан ключ `valarr`, то ключи `compare` и `value` игнорируются.

**Формат `compare`:**

Значение | Описание
------------ | ------------
EQL | Равно (по умолчанию). 
NEQ | Не равно. 
LSS | Меньше. 
LEQ | Меньше или равно. 
GTR | Больше. 
GEQ | Больше или равно. 
GIN | Для поиска вхождений JSON. 
LKE | LIKE - Значение ключа `value` должно передаваться вместе со знаком '%' в нужном месте;
ISN | Ключ `value` должен быть опушен (не указан). 
INN | Ключ `value` должен быть опушен (не указан). 

**Примеры:**

```http request
POST /api/v1/object/geolocation/list HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Basic YWRtaW46YWRtaW4=

{"filter": {"object": 2, "code": "default"}}
````

```http request
POST /api/v1/address/list HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Basic YWRtaW46YWRtaW4=

{"fields": ["description"], "search": [{"field": "apartment", "compare": "GEQ", "value": "5"}]}
````

## Геолокация
### Координаты геолокации
```http request
POST /api/v1/object/geolocation[/get | /set]
```
Получить или установить координаты геолокации для объекта. 

Где:
  * `/get` - `Получить`  
  * `/set` - `Установить`  

При отсутствии `/get` или `/set` работает следующее правило:

 * Если значение `coordinates` не указано или равно `null`, то метот работает как `Получить` иначе как `Установить`.

### Установить
```http request
POST /api/v1/object/geolocation/set
```
Установить координаты геолокации для объекта. 

**Параметры:**

Имя | Тип | Значение | Описание
------------ | ------------ | ------------ |------------
id | NUMERIC |  | Идентификатор объекта.
coordinates | JSON array | null OR json | Массив JSON объектов с координатами.
  
**Формат `coordinates`:**

Ключ | Тип | Описание
------------ | ------------ | ------------
id | NUMERIC | Идентификатор
code | STRING | Код
name | STRING | Наименование
latitude | NUMERIC | **Обязательный**. Широта
longitude | NUMERIC | **Обязательный**. Долгота
accuracy | NUMERIC | Точность (высота над уровнем моря)
description | STRING | Описание

Если ключ `id` не указан то действие считается как `Добавить`. Если ключ `id` указан и значение ключа `name` не `null` то действие считается как `Обновить` иначе как `Удалить`. Значения не указанных ключей считаются как `null`.   

### Получить
```http request
POST /api/v1/object/geolocation/get
```
Получить координаты геолокации для объекта. 

**Параметры:**

Имя | Тип | Значение | Описание
------------ | ------------ | ------------ |------------
id | NUMERIC |  | Идентификатор объекта
fields | JSON | [field, field, ...] | Поля

Где `fields` - это массив JSON STRING наименований полей в таблице, если не указано то запрос вернет все поля.  

### Список
```http request
POST /api/v1/object/geolocation/list
```
Получить координаты геолокации в виде списка. 

**Параметры:**
[Общие параметры для объекта](#общие-параметры)

## Метод
```http request
POST /api/v1/method[/list | /get]
```
Запросить информацию о методах документооборота.

`/list` предоставит список всех доступных методов. 

Для `/get` доступен как минимум один из **параметров** указанный в теле запроса:

Имя | Тип | Описание
------------ | ------------ | ------------
object | NUMERIC | Идентификатор объекта
class | NUMERIC | Идентификатор класса
state | NUMERIC | Идентификатор состояния
classcode | STRING | Код класса (вместо идентификатора)
statecode | STRING | Код состояния (вместо идентификатора)
  
**Пример:**

Запрос:
```http request
POST /api/v1/method/get HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded
Authorization: Basic YWRtaW46YWRtaW4=

classcode=client&statecode=enabled
```

Ответ:
```json
[
  {"id":100000000211,"parent":null,"action":100000000053,"actioncode":"disable","label":"Закрыть","visible":true},
  {"id":100000000212,"parent":null,"action":100000000054,"actioncode":"delete","label":"Удалить","visible":true}
]
```