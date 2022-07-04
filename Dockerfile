FROM openjdk:11

# Just matched `app/build.gradle`
ENV ANDROID_COMPILE_SDK "30"

# Just matched `app/build.gradle`
ENV ANDROID_BUILD_TOOLS "30.0.2"

# Version from https://developer.android.com/studio/releases/sdk-tools
ENV ANDROID_SDK_TOOLS "7583922"
ENV ANDROID_HOME /android-sdk-linux
ENV PATH="${PATH}:/android-sdk-linux/platform-tools/"

# Install OS packages
RUN apt-get --quiet update --yes
RUN apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev

# Install Android SDK
RUN wget --quiet --output-document=android-sdk.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS}_latest.zip"
RUN unzip -d ${ANDROID_HOME} android-sdk.zip
RUN yes | ./android-sdk-linux/cmdline-tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}" --sdk_root=android-sdk-linux/
RUN yes | ./android-sdk-linux/cmdline-tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS}" --sdk_root=android-sdk-linux/

# Install Fastlane
COPY Gemfile .
RUN gem install bundler
RUN bundle install
RUN gem install fastlane-plugin-firebase_app_distribution

# Clean cache
RUN apt-get clean autoclean
RUN apt-get autoremove --yes
RUN rm -rf /var/lib/{apt,dpkg,cache,log}/
