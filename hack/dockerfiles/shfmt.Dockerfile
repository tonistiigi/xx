# syntax=docker/dockerfile:1.8
# check=error=true

FROM mvdan/shfmt:v3.8.0-alpine AS shfmt
WORKDIR /src
ARG SHFMT_FLAGS="-i 2 -ci"

FROM shfmt AS generate
WORKDIR /out
RUN --mount=target=/src <<EOF
  set -ex
  cp -a /src/* ./
  for f in */xx-*; do 
    shfmt -l -w -ln posix $SHFMT_FLAGS "$f";
  done
  for f in */test-*.bats; do
    shfmt -l -w -ln bats $SHFMT_FLAGS "$f";
  done
EOF

FROM scratch AS update
COPY --from=generate /out /

FROM shfmt AS validate
RUN --mount=type=bind <<EOF
  set -ex
  for f in */xx-*; do
    shfmt -ln posix $SHFMT_FLAGS -d "$f"
  done
  for f in */test-*.bats; do
    shfmt -ln bats $SHFMT_FLAGS -d "$f"
  done
EOF
