FROM golang:1.20.3-alpine

ARG HUGO_VERSION=0.120.4

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

WORKDIR /src

# Required for PostCSS
RUN npm install -G \
    autoprefixer \
    postcss-cli

RUN CGO_ENABLED=1 go install -tags extended github.com/gohugoio/hugo@v${HUGO_VERSION} && \
    addgroup -Sg 1000 hugo && \
    adduser -Sg hugo -u 1000 -h /src hugo

USER hugo:hugo

EXPOSE 1313
