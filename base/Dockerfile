#syntax=docker/dockerfile:1.2
ARG TEST_BASE_TYPE=alpine
ARG TEST_BASE_IMAGE=${TEST_BASE_TYPE}

ARG SHADOW_VERSION=4.8.1

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

FROM --platform=$BUILDPLATFORM alpine AS binutils-base
RUN apk add --no-cache git clang lld zlib-dev gcc patch make musl-dev
WORKDIR /work
# BINUTILS_PATCHES_VERSION defines version of aports to use for patches
ARG BINUTILS_PATCHES_VERSION=3.13-stable
RUN git clone --depth 1 -b ${BINUTILS_PATCHES_VERSION} https://github.com/alpinelinux/aports.git && \
    mkdir patches && \
    cp -a aports/main/binutils/*.patch patches/ && \
    rm -rf aports
COPY --from=base / /
ARG BINUTILS_VERSION=2.35
ARG TARGETPLATFORM
# first build version for current architecture that is used then cross compiling
RUN export CC=xx-clang CXX=xx-clang++ LD=lld BINUTILS_TARGET=${TARGETPLATFORM} && unset TARGETPLATFORM && \
    wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz && \
    tar xf binutils-${BINUTILS_VERSION}.tar.gz && \
    cd binutils-${BINUTILS_VERSION} && \
    for f in ../patches/*; do patch -p1 < $f; done && \
    ./configure --disable-separate-code --libdir=/lib --prefix=/usr --disable-multilib --enable-deterministic-archives --target=$(TARGETPLATFORM=$BINUTILS_TARGET xx-info) --disable-nls && \
    make -j $(nproc) && \
    make install && \
    cd ..  && rm -rf binutils-${BINUTILS_VERSION}

RUN xx-apk add --no-cache musl-dev gcc g++ zlib-dev
#RUN apk add --no-cache file && ls -l /usr/bin && fail
# BINUTILS_TARGET defines platform that binutils binaries will target when run
ARG BINUTILS_TARGET
# BINUTILS_CFLAGS defines C compiler flags when building binutils
ARG BINUTILS_CFLAGS="-Wl,-s -Os"
# BINUTILS_CONFIG defines extra options passed to binutils configure script
ARG BINUTILS_CONFIG=
RUN export CC=xx-clang CXX=xx-clang++ LD=lld CFLAGS="-Wl,-s -Os" CXXFLAGS=-Wl,-s && \
    tar xf binutils-${BINUTILS_VERSION}.tar.gz && \
    cd binutils-${BINUTILS_VERSION} && \
    for f in ../patches/*; do patch -p1 < $f; done && \
    ./configure --disable-separate-code --libdir=/lib --prefix=/out --disable-multilib --enable-deterministic-archives --target=$(TARGETPLATFORM=$BINUTILS_TARGET xx-info) --host $(xx-clang --print-target-triple) --disable-nls --enable-gold --enable-relro --enable-plugins --with-pic --with-mmap --with-system-zlib $BINUTILS_CONFIG && \
    make -j $(nproc) && \
    make install && \
    cd ..  && rm -rf binutils-${BINUTILS_VERSION} && \
    for f in /out/bin/*; do xx-verify $f; done

FROM scratch AS binutils
COPY --from=binutils-base /out /usr/

FROM base
