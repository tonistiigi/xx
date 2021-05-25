# syntax = docker/dockerfile:1.2
FROM mvdan/shfmt:v3.2.1-alpine AS shfmt
WORKDIR /src
ARG SHFMT_FLAGS="-i 2 -ci"

FROM shfmt AS generate
WORKDIR /out
RUN --mount=target=/src \
  cp -a /src/* ./ && \
  shfmt -l -w -ln posix $SHFMT_FLAGS . && \
  for f in */test-*.bats; do shfmt -l -w -ln bats $SHFMT_FLAGS "$f"; done

FROM scratch AS update
COPY --from=generate /out /

FROM shfmt AS validate
RUN --mount=target=. \
  shfmt -ln posix $SHFMT_FLAGS -d . && \
  for f in */test-*.bats; do shfmt -ln bats $SHFMT_FLAGS -d "$f" || return; done;
