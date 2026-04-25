# syntax=docker/dockerfile:1.23
# check=error=true

FROM koalaman/shellcheck-alpine:v0.11.0
WORKDIR /src
RUN --mount=type=bind,src=src shellcheck xx-*