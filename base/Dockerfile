ARG TEST_BASE=alpine

FROM scratch AS base
COPY xx-* /usr/bin/

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS bats-assert

FROM ${TEST_BASE} AS test
RUN pkginstall() { if [ -f /sbin/apk ]; then apk add --no-cache $@; else apt-get update && apt-get install -y $@; fi }; pkginstall bats
WORKDIR /work
COPY --from=bats-assert . .
COPY --from=base / /
COPY test-*.bats .
ARG TEST_BASE
ARG TEST_CMDS
RUN [ "${TEST_CMDS:-info}" = "${TEST_CMDS#*info}" ] && exit 0; ./test-info-common.bats && ./test-info-${TEST_BASE}.bats
RUN [ "${TEST_CMDS:-apk}" = "${TEST_CMDS#*apk}" ] && exit 0; [ "${TEST_BASE}" != "alpine" ] || ./test-apk.bats

FROM alpine AS dev
RUN apk add --no-cache vim
COPY --from=base / /
ENTRYPOINT ["/bin/ash"]

FROM base
