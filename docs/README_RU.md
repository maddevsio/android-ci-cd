### android-ci-cd

* Мобильная разработка так же как и любая другая, требует написание кода, который
должен проходить все возможные проверки. В данном случае, чтобы исключить человеческий фактор,
мы можем автоматизировать процессы проверки и поставки готового приложения в тестовую
и продакшен среду.

### Структура репозитория: 

```
.
├── app
│   ├── build.gradle
│   ├── google-services.json
│   └── src
├── build.gradle
├── Dockerfile
├── fastlane
│   ├── Appfile
│   ├── Fastfile
│   ├── Pluginfile
│   ├── README.md
│   └── report.xml
├── Gemfile
├── gradle
│   └── wrapper
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradle.properties
├── gradlew
├── gradlew.bat
├── ic_launcher-web.png
├── libs
│   └── android-support-v4.jar
├── proguard-project.txt
├── project.properties
├── README.md
├── release-notes.txt
└── settings.gradle
```

### Зависимости

* gitlab-ci + gitlab-runner
* docker
* Fastlane
* Firebase
* Google Play

### Описание основных компонентов

![main](android-ci-cd-tools.drawio.svg)

```
app                          -- Директория в которой хранится код приложения.
Fastlane                     -- Файлы и для настройки Fastlane
.gitlab-ci.yml               -- CI/CD pipeline
Dockerfile                   -- Докер файл для сборки докер базоого образа, который используется для запуска тестов, сборки и деплоя приложения. 
Gemfile                      -- Файл с описание зависимостей для RUBY.
app/build.gradle             -- Описание настроек сборки приложения. 
```

### С чего начать

1. Создать google project в GCP
2. Создать проект в Firebase
3. Создать проект в Google play

#### Подготовка ключей и переменных окружения

* В директорию приложения необходимо добавить json файл с настройками проекта firebase.

```
app/google-services.json
```

Файл с настройками можно скачать в Firebase. Перейти в [консоль](https://console.firebase.google.com/)

```
Выберите свое созданное приложение --> в Project Overview выберете 
Project seting  --> Внизу страницы скачайте google-services.json
```

* Создание Service Account для деплоя приложения в Firebase 

```
Выберите свое созданное приложение --> в Project Overview выберете 
Project seting  --> Service Account --> create service account 
```
Добавить ключ в переменную можно закодировав его в base64 командой
```
base64 Имя_файла > key_firebase
cat key_firebase
```
Скопируйте полученный вывод и перейдите в 
```
Gitlab --> Settings --> CI/CD --> Variables -->Add variable
```

В строку Key впишите SA_JSON_KEY в Value добавите скопированный ключ

Для подписи приложения необходим ключ, который можно сгенерировать онлайн или при помощи команды
```
keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
```

Добавить ключ в переменную можно также закодировав его в base64 командой
```
base64 Имя_файла > keystore
cat keystore
```
Скопируйте полученный вывод и перейдите в 
```
Gitlab --> Settings --> CI/CD --> Variables -->Add variable
```
В строку Key впишите KEYSTORE в Value добавите скопированный ключ


##### Описание переменных окружения

````
KEYSTORE                -- Закодированный в base64 keystore ключ для Google play (base64)
KEYSTORE_PW             -- Пароль от keystore
ALIAS                   -- Значение введенное при создании ключа для подписи
ALIAS_PW                -- Пароль от ALIAS
SA_JSON_KEY             -- Ключ от Service Account для Firebase (base64)
SA_JSON_GP_KEY          -- Ключ от Service Account для Google Play Console (base64)
APP_VERSION_NAME        -- Версия приложения
FIREBASE_APP_ID         -- ID приложения в Firebase
SLACK_WEBHOOK_URL       -- Webhook канала slack
BUILD_TASK              -- Название таска в gradle (assemble, bundle, test)
BUILD_TYPE              -- Тип билда (assemble, release)
````
> Если проект лежит не в основной директории, то можно задать путь к каталогу проекта через переменную PROJECT_DIR в Fastfile


### Fastlane 

* Fastlane необходим для удобной доставки артефакта в Firebase и Google play.

#### Appfile 

* json_key_file            -- Путь к ключу для авторизации в Google play и Firebase.
* package_name             -- Название приложения. Указывается  в файле build.gradle в директории 
                               `/app/` В блоке `android/defaultConfig` в строке `applicationId` 

# Fastfile

* Основной файл в котором указываются настройки по сборке и отправке приложения в Firebase и Google play

* Пример, первой функции build_release:

```
desc         -- Описание функции 
lane         -- Название функции
task         -- Указывается формат сборки. Возможо указать bundle - aab формат и assemble - apk формат.
build_type   -- Указывается тип сборки. 
properties   -- Блок дополнительных настроек используемых при сборке приложения, например подпись приложения ключем.
```

# Pluginfile

В этом файле описывается необходимые плагины для Fastlane.

В нашем примере это - плагин необходимы для отправки приложения в Firebase:

```
fastlane-plugin-firebase_app_distribution 
```

## CI/CD 

![flow](android-ci-cd-CI-CD-flow.drawio.svg)

* Стоит объяснить, для чего используются несколько разных сборок.

Условия: 
* Приложения в формате `apk` нельзя загружать в Google play
* Приложения в формате `aab` можно загружать в firebase и google play

2. Для удобства разработки, на этапе Merge Request, мы даем возможность собрать приложение по требованию и отправить его в Firebase.
* Удобно проверять свои наработки без мерджа кода в основную ветку.
* Собранное приложение в формате `apk` доступно в виде артефакта в пайплайне

* В CI/CD 4 шага:

```
  - build_base_image
  - tests
  - lint
  - deploy_staging
  - deploy_prod
```

### Build-base-image

* На этом шаге собирается базовый образ из Dockerfile и пушится в репозиторий, который будет использоваться в 
следующих шагах. Если Dockerfile не был изменен, то будет использоваться последний образ.

### Tests
* На этом шаге будут запущены unit тесты и линтер

### deploy_staging

* Из переменных окружения передаются необходимые ключи в каталог с проектом.
* Запустится сборка приложения и его деплой в Firebase.

### deploy_prod

* Из переменных окружения передаются необходимые ключи в каталог с проектом.
* Запустится сборка приложения и его деплой в Firebase, после успешного деплоя, станет доступной возможность деплоя приложения в google play.



