# syntax = docker/dockerfile:1.2
FROM koalaman/shellcheck-alpine:v0.7.2
WORKDIR /src
COPY base .
RUN shellcheck xx-*