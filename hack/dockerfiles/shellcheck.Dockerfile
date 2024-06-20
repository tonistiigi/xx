# syntax=docker/dockerfile:1.8
# check=error=true

FROM koalaman/shellcheck-alpine:v0.10.0
WORKDIR /src
RUN --mount=type=bind,src=src shellcheck xx-*