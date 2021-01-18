#syntax=docker/dockerfile:1.2
ARG TEST_BASE_TYPE=alpine
ARG TEST_BASE_IMAGE=${TEST_BASE_TYPE}

FROM --platform=$BUILDPLATFORM alpine AS scripts
COPY xx-* /out/
RUN ln -s xx-cc /out/xx-clang && \
    ln -s xx-cc /out/xx-clang++ && \
    ln -s xx-cc /out/xx-c++ 

FROM scratch AS base
COPY --from=scripts /out/ /usr/bin/

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS assert

FROM ${TEST_BASE_IMAGE} AS test-base-alpine
RUN --mount=type=cache,target=/pkg-cache \
    ln -s /pkg-cache /etc/apk/cache && \
    apk add bats vim
WORKDIR /work

FROM ${TEST_BASE_IMAGE} AS test-base-debian
RUN --mount=type=cache,target=/pkg-cache \
    rm -rf /var/cache/apt/archives && \
    ln -s /pkg-cache /var/cache/apt/archives && \
    rm /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "1";' > /etc/apt/apt.conf.d/keep-downloads && \
    apt update && apt install --no-install-recommends -y bats vim
WORKDIR /work


FROM test-base-${TEST_BASE_TYPE} AS test
COPY --from=assert . .
COPY --from=base / /
COPY fixtures fixtures
COPY test-*.bats test_helper.bash .
ARG TEST_BASE_TYPE
ARG TEST_CMDS
RUN [ "${TEST_CMDS:-info}" = "${TEST_CMDS#*info}" ] && exit 0; ./test-info-common.bats && ./test-info-$(echo $TEST_BASE_TYPE | cut -d: -f1).bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-apk}" = "${TEST_CMDS#*apk}" ] && exit 0; [ ! -f /etc/alpine-release ] || ./test-apk.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-apt}" = "${TEST_CMDS#*apt}" ] && exit 0; [ ! -f /etc/debian_version ] || ./test-apt.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-verify}" = "${TEST_CMDS#*verify}" ] && exit 0; ./test-verify.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-clang}" = "${TEST_CMDS#*clang}" ] && exit 0; ./test-clang.bats
RUN --mount=type=cache,target=/pkg-cache \
    --mount=target=/root/.cache,type=cache \
    [ "${TEST_CMDS:-golang}" = "${TEST_CMDS#*golang}" ] && exit 0; ./test-go.bats

FROM test-base-${TEST_BASE_TYPE} AS dev
COPY fixtures fixtures
COPY --from=base / /


ARG SHADOW_VERSION=4.8.1
# newuidmap & newgidmap binaries (shadow-uidmap 4.7-r1) shipped with alpine cannot be executed without CAP_SYS_ADMIN,
# because the binaries are built without libcap-dev.
# So we need to build the binaries with libcap enabled.
FROM --platform=$BUILDPLATFORM alpine AS idmap
RUN apk add --no-cache git autoconf automake clang lld gettext-dev libtool make byacc binutils
COPY --from=base / /
ARG SHADOW_VERSION
RUN git clone https://github.com/shadow-maint/shadow.git /shadow && cd /shadow && git checkout $SHADOW_VERSION
WORKDIR /shadow
ARG TARGETPLATFORM
RUN xx-apk add --no-cache musl-dev gcc libcap-dev
RUN CC=$(xx-clang --print-target-triple)-clang ./autogen.sh --disable-nls --disable-man --without-audit --without-selinux --without-acl --without-attr --without-tcb --without-nscd --host $(xx-clang --print-target-triple) \
  && make -j $(nproc) \
  && xx-verify src/newuidmap src/newuidmap \
  && cp src/newuidmap src/newgidmap /usr/bin

FROM scratch AS idmap-binaries
COPY --from=idmap /usr/bin/newuidmap /usr/bin/newgidmap /

FROM base
