ARG TEST_BASE=alpine

FROM alpine AS scripts
COPY xx-* /out/
RUN ln -s xx-cc /out/xx-clang && \
    ln -s xx-cc /out/xx-clang++ && \
    ln -s xx-cc /out/xx-c++ 

FROM scratch AS base
COPY --from=scripts /out/ /usr/bin/

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS assert

FROM ${TEST_BASE} AS test
RUN --mount=type=cache,target=/pkg-cache \
    ln -s /pkg-cache /etc/apk/cache; \
    pkginstall() { if [ -f /sbin/apk ]; then apk add --no-cache $@; else apt-get update && apt-get install -y $@; fi };\
    pkginstall bats
WORKDIR /work
COPY --from=assert . .
COPY --from=base / /
COPY fixtures fixtures
COPY test-*.bats .
ARG TEST_BASE
ARG TEST_CMDS
RUN [ "${TEST_CMDS:-info}" = "${TEST_CMDS#*info}" ] && exit 0; ./test-info-common.bats && ./test-info-${TEST_BASE}.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-apk}" = "${TEST_CMDS#*apk}" ] && exit 0; [ "${TEST_BASE}" != "alpine" ] || ./test-apk.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-verify}" = "${TEST_CMDS#*verify}" ] && exit 0; ./test-verify.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-clang}" = "${TEST_CMDS#*clang}" ] && exit 0; [ "${TEST_BASE}" != "alpine" ] || ./test-clang.bats
RUN --mount=type=cache,target=/pkg-cache \
    --mount=target=/root/.cache,type=cache \
    [ "${TEST_CMDS:-golang}" = "${TEST_CMDS#*golang}" ] && exit 0; [ "${TEST_BASE}" != "alpine" ] || ./test-go.bats

FROM alpine AS dev
RUN apk add --no-cache vim
WORKDIR /work
COPY fixtures fixtures
COPY --from=base / /
ENTRYPOINT ["/bin/ash"]

FROM base
