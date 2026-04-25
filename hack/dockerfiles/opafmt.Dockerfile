# syntax=docker/dockerfile:1.23
# check=error=true

FROM openpolicyagent/opa:1.15.2-static AS opa-bin

FROM alpine AS opafmt
COPY --from=opa-bin /opa /usr/bin/opa
WORKDIR /src

FROM opafmt AS generate
WORKDIR /out
RUN --mount=target=/src <<EOF
  set -ex
  find /src -name '*.rego' -type f | while read -r f; do
    rel="${f#/src/}"
    mkdir -p "$(dirname "$rel")"
    cp -a "$f" "$rel"
  done
  opa fmt -w .
EOF

FROM scratch AS update
COPY --from=generate /out /

FROM opafmt AS validate
RUN --mount=type=bind <<EOF
  set -ex
  opa fmt --fail -d .
EOF
