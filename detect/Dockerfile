FROM scratch AS detect
COPY xx-detect /usr/bin/

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS bats-assert

FROM alpine AS test-alpine
RUN apk add --no-cache bats
WORKDIR /work
COPY --from=bats-assert . .
COPY --from=detect / /
COPY test-common.bats test-alpine.bats .
RUN ./test-common.bats && ./test-alpine.bats

FROM debian:buster AS test-debian
RUN apt-get update && apt-get install -y bats
WORKDIR /work
COPY --from=bats-assert . .
COPY --from=detect / /
COPY test-common.bats test-debian.bats .
RUN ./test-common.bats && ./test-debian.bats

FROM alpine AS dev
RUN apk add --no-cache vim
COPY --from=detect / /
ENTRYPOINT ["/bin/ash"]

FROM detect