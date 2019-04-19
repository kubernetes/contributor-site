FROM alpine:latest
ARG HUGO_VERSION=${HUGO_VERSION}

RUN apk add --no-cache \
    bash  \
    git   \
    grep  \
    rsync \
    sed

RUN wget -q0- https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz | \
    tar xvz hugo -C /usr/local/bin \
 && mkdir -p /src \
 && addgroup -Sg 1000 hugo \
 && adduser -Sg hugo -u 1000 -g 1000 -h /src hugo

WORKDIR /src

EXPOSE 1313

USER hugo:hugo

SHELL [ "/bin/bash", "-c" ]
