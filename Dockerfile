# 1: Use ruby 2.7 as base:
FROM ruby:2.7

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential

ENV BUNDLER_VERSION='2.4.22'
RUN gem install bundler -v ${BUNDLER_VERSION}

# 2: We'll set the application path as the working directory
WORKDIR /app

# 3: We'll add the app's binaries path to $PATH:
ENV PATH=$PATH:/app/bin

ENV BUNDLE_GITHUB__HTTPS=true BUNDLE_MAJOR_DEPRECATIONS=true
