# syntax = docker/dockerfile:1.5
FROM koalaman/shellcheck-alpine:v0.7.2
WORKDIR /src
COPY src .
RUN shellcheck xx-*