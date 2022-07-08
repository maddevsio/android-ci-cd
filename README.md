# Android CI/CD boilerplate

[![Developed by Mad Devs](https://maddevs.io/badge-dark.svg)](https://maddevs.io?utm_source=github&utm_medium=madboiler)
[![License](https://img.shields.io/github/license/maddevsio/android-ci-cd)](https://github.com/maddevsio/android-ci-cd/blob/main/LICENSE.md)

Stop publishing your Android apps manually and start doing this in fully automated fashion to any stage (test, beta, prod).

---

## Advantages of this boilerplate

* `Quick start CI/CD`: With this boilerplate you can easily build the CI/CD for your android app based on `fastlane`.
* `Easy adaptation to external CI/CD tools`: We use `gitlab-ci` or `github actions` as the executor fastlane commands and the construction of the workflow. 
* `Notification`: Pipeline operation Slack notifications, notifications about successful operations or errors in the pipeline process.  
* `No special build machine setup required`: We build the application inside a docker container with all the dependencies installed, this provides portability, and the ability to use standard `github` agents or `gitlab` runners. 

## CI/CD 

* Let's try to answer some questions:
  * [What is CI/CD](https://en.wikipedia.org/wiki/CI/CD) ?
    * Above all, CI/CD allows you to increase productivity through automation. As in the manufacturing industry, 
      you can automate the repetitive assembly process (application assembly) with automated workers, allowing developers to focus on value-added design and development processes.
  * What are the benefits of using CI/CD in mobile development ?
    1. `Faster release cycles`
       * With CI/CD, developers get used to making even the smallest code changes, as they will be built and delivered automatically in the background. This automated flow ensures that there is always an alpha or beta release ready for testing with the latest code. 
    2. `Faster feedback/response with "continuous integration"`
       * With a faster release cycle with fewer changes, it becomes possible to pinpoint the source of a bug when a problem is identified. This is especially important for large teams where code conflicts can cause significant problems.
    3. `Improve coding discipline with query-based assembly and automated tests`
       * With a pull request commit, the build occurs before the merge, followed by automatic unit testing and code verification after each merge; the code itself is tested more thoroughly before it becomes part of the release.
    4. `Early warning and increased testing with "continuous deployment"`
       * By testing each individual change with multiple steps in the testing workflow, problems can be identified faster.
    5. `Isolation from the complexities associated with application delivery`
       * Every development discipline has its own set of complexities, and mobile apps are no exception. Android have completely independent and different processes for creating, signing, distributing, and installing apps. CI/CD helps to automate this process.

### CI/CD description

* This diagram describes the flow which we use

![flow](docs/android-ci-cd-CI-CD-flow.drawio.svg)

* Step descriptions

```
  - build base image                - Step for build base image which used for build application. 
  - tests and lints                 - Step for run tests and lints.
  - build and deploy to firebase    - Step for build and deploy application to Firebase.
  - build and deploy to google play - Step for build and deploy application and Google Play.
```

* It is worth explaining what several builds are used for.

Terms and conditions:
* Applications in `apk` format cannot be uploaded to Google Play
* Applications in `aab` format can be uploaded in Firebase and Google Play
* Applications in `apk` stored in artifacts and can be downloaded from pipeline artifacts

Because of it we have to build several builds.

* For the convenience of testing, at the stage of `Merge Request`, we give the opportunity to build the application on demand and send it to `Firebase`.
* It is convenient to check your application without merge code to the main branch.
* The application in `apk` format is available as an artifact in the pipeline.

### Feature

* GitLab: 
  * We have manual step to deploy application to the `Google Play`. 
  * We have manual step for build and deploy application to staging `Firebase`, this step available on `Merge Request`.
* GitHub:
  * We use [trstringer/manual-approval](https://trstringer.com/github-actions-manual-approval/) action which help to create manual approve in the deploy to `Google Play`.
  * We use manual job - workflow_dispatcher for build and deploy application from any branch. 

### Tools and services

* [Fastlane](https://fastlane.tools/) - Fastlane is a tool for iOS and Android developers to automate tedious tasks like generating screenshots, dealing with provisioning profiles, and releasing your application.
* [gitlab-ci](https://docs.gitlab.com/ee/ci/) or [GitHub Actions](https://docs.github.com/en/actions)  - CI/CD systems are used to build the pipeline logic and to execute fastlane lanes.
* [docker](https://www.docker.com/) - Docker is used as the build environment for the application         
* [CGP](https://cloud.google.com/) 
  * [Firebase](https://firebase.google.com/docs/app-distribution) - Testing environment for application.
  * [Google Play](https://play.google.com/console/about/) - Production environment for application.

### Description of main components

![main](docs/android-ci-cd-tools.drawio.svg)

### Repository structure

```commandline
.
├── app               - Folder which contains example application
│   ├── build.gradle  - File for android project configuration 
│   └── src      
├── build.gradle    
├── Dockerfile        - Dockerfile for base image which used in build step
├── docs              - Folder for documentation
├── fastlane          - Folder with fastlane configuration
│   ├── Appfile       - File for main fastlane configuration 
│   ├── Fastfile      - File for configuration fastlane actions
│   └── Pluginfile    - File for configuration fastlane dependencies
├── Gemfile                
├── gradle                  - Folder for gradle build tool 
├── gradle.properties       - File for gradle configuration
├── gradlew
├── gradlew.bat
├── ic_launcher-web.png
├── libs
├── proguard-project.txt
├── project.properties
├── README.md              
└── settings.gradle        - File for graddle setting
```

### From scratch

1. [Create account in Google cloud platform](https://cloud.google.com/)
2. [Create Google cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
3. [Create Firebase project and activate app distribution](https://cloud.google.com/firestore/docs/client/get-firebase)
4. [Create Google Play developer account](https://play.google.com/console/about/)

#### Preparation keys and environment variables

1. Json file with configuration for Firebase 
    * You must add a json file with the Firebase project settings encoded to base64 to the environment variable.
      > https://firebase.google.com/docs/android/setup - Step 3
      ```bash
      base64 google-services.json > firebase_setting
      ```

2. Service account with access to Firebase
    * Create Service Account for release application to Firebase
      > Choose your Firebase account --> Project Overview --> Project setting --> Service Account --> create service account 
    * Add SA key encoded to base64 to environment variable.
      ```bash
      base64 sa.json > key_firebase
      ```

3. Service account with access to Google Play
    * Create Service Account for release application to [Google Play](docs/README_GOOGLE_PLAY.md)
    * Add SA key encoded to base64 to environment variable
      ```bash
      base64 google_play.json > google_play
      ```

4. Keystore for signing application
    * To sign an application, you need a key, which can be generated with the command.
      ```bash
      keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
      ```
    * Add signing keystore encoded to base64 to environment variable.
      ```bash
      base64 my-release-key.keystore > keystore
      ```

##### GitLab CI/CD 

* We use `Environments` in our pipeline to divide our variables by environments, before you start please create 3 environment in `gitlab-ci-cd`: 

```
GitLab --> Deployments --> Environment --> New Environment
```

* We need to create three environments:
  * staging
  * prod
  * prod-gp

##### GitHub Actions

* We can use environments in GitHub Actions, but the environments available only in public repositories or in corporate subscriptions.
* In this boilerplate we don't use environments in GitHub Actions.

##### Prepare environment variables

1. Copy content of this file `firebase_setting`:
    ```
    GitLab --> Settings --> CI/CD --> Variables --> Add variable
    ```
    or
    ```
    GitHub --> Settings --> Secrets --> Actions --> New repository secret
    ```

    > In the key field paste `GOOGLE_SERVICES_JSON` in the value field paste your `google-services.json` encoded to base64.

2. Copy content of this file `key_firebase`: 
    ```
    GitLab --> Settings --> CI/CD --> Variables --> Add variable
    ```
    or
    ```
    GitHub --> Settings --> Secrets --> Actions --> New repository secret
    ```

    > In the key field paste `SA_JSON_KEY` in the value field paste your `sa.key` encoded to base64.

3. Copy content of this file `google_play`: 

    ```
    GitLab --> Settings --> CI/CD --> Variables --> Add variable
    ```
    or
    ```
    GitHub --> Settings --> Secrets --> Actions --> New repository secret
    ```

    > In the key field paste `SA_JSON_GP_KEY` in the value field paste your `google_play.json` encoded to base64.

4. Copy content of this file `keystore`: 

    ```
    GitLab --> Settings --> CI/CD --> Variables --> Add variable
    ```
    or
    ```
    GitHub --> Settings --> Secrets --> Actions --> New repository secret
    ```
    > In the key field paste `KEYSTORE` in the value field paste your signing key encoded to base64.

##### Environment variables

| NAME                        |     ENVIRONMENT      |                                                                                                                                    DESCRIPTION |
|-----------------------------|:--------------------:|-----------------------------------------------------------------------------------------------------------------------------------------------:|
| KEYSTORE                    |         ALL          |                                                                                                    Encoded to base64 signing keystore (base64) |
| KEYSTORE_PW                 |         ALL          |                                                                                                                  Password for signing keystore |
| ALIAS                       |         ALL          |                                                                                                                                 Keystore alias |
| ALIAS_PW                    |         ALL          |                                                                                                                    Password for keystore alias |
| SA_JSON_KEY                 |     STAGING/PROD     |                                                                                                      Service Account key for Firebase (base64) |
| SA_JSON_GP_KEY              |       PROD-GP        |                                                                                           Service account key for Google Play Console (base64) |
| GOOGLE_SERVICES_JSON        |         ALL          |                                                                                                           Main configuration file for Firebase |
| APP_VERSION_NAME            | STAGING/PROD/PROD-GP |                                                                                                                            Application version |
| FIREBASE_APP_ID             |     STAGING/PROD     |                                                                                                                     Application ID in Firebase |
| BUILD_TASK                  | STAGING/PROD/PROD-GP |                                                                                                   Task name in gradle (assemble, bundle, test) |
| BUILD_TYPE                  | STAGING/PROD/PROD-GP |                                                                                                                 Build type (assemble, release) |
| SLACK_WEBHOOK_URL           |         ALL          |                                                                                                                                  Slack webhook |
| FIREBASE_TESTER_GROUP_NAME  |     STAGING/PROD     |                                                                                                              Name of testers group in Firebase |
| APPROVERS                   |         ALL          |                                                                         List of approvers for Google Play release, used only in GitHub Actions |
| CI_PIPELINE_ID              |         ALL          |                            Pipeline ID used for `versionCode`, by default declared in the GitLab, in the GitHub Actions used github.run_number |
| CI_COMMIT_BEFORE_SHA        |         ALL          |                   Previous commit, used for build changelog, by default declared in the GitLab, in the GitHub Actions used github.event.before |
| FIREBASE_ARTIFACT_TYPE      |     STAGING/PROD     |                                                                                                        Artifact type for Firebase distribution |
| PROJECT_DIR                 |         ALL          | If the project is not in the main directory, you can specify the path to the project directory through the `PROJECT_DIR` variable in Fastfile. |
| APP_PACKAGE_NAME            |         ALL          |                                                                 The default android package name for example we use `com.boiler.android.hello` |

* When you complete all this preparation you can start build and release application to Firebase

### Additional configuration

#### Configuration plugins for Fastlane

* We have `Pluginfile` in this file we can configure plugins for Fastlane, by default we use `fastlane-plugin-firebase_app_distribution` 
