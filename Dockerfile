FROM alpine:latest
ARG HUGO_VERSION=0.69.2

RUN apk add --no-cache \
    bash \
    build-base \
    curl \
    git \
    grep \
    libc6-compat \
    rsync \
    sed \
    npm

WORKDIR /src

# Required for PostCSS
RUN npm install -G \
    autoprefixer \
    postcss-cli

RUN mkdir -p /usr/local/src && \
    cd /usr/local/src && \
    curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz | tar -xz && \
    mv hugo /usr/local/bin/hugo && \
    addgroup -Sg 1000 hugo && \
    adduser -Sg hugo -u 1000 -h /src hugo


USER hugo:hugo

EXPOSE 1313
