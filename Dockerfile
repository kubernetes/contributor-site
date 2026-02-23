FROM alpine:latest

# Specify HUGO_VERSION, or work it out automatically by using
# "make container-image"
ARG HUGO_VERSION
ARG TARGETARCH
ARG GO_VERSION=1.22.5

RUN apk add --no-cache \
    bash \
    build-base \
    curl \
    git \
    grep \
    gcompat \
    libc6-compat \
    rsync \
    sed \
    npm

RUN curl -sSfL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" -o /tmp/go.tgz \
    && tar -xz -C /usr/local -f /tmp/go.tgz \
    && rm /tmp/go.tgz

ENV PATH="/usr/local/go/bin:${PATH}"
WORKDIR /src

COPY package*.json ./

RUN npm ci --ignore-scripts

RUN mkdir -p /usr/local/src && \
    cd /usr/local/src && \
    curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz | tar -xz && \
    mv hugo /usr/local/bin/hugo && \
    addgroup -Sg 1000 hugo && \
    adduser -Sg hugo -u 1000 -h /src hugo


USER hugo:hugo

EXPOSE 1313
