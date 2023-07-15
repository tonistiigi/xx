# syntax=docker/dockerfile:1.5

ARG TEST_BASE_TYPE=alpine
ARG TEST_BASE_IMAGE=${TEST_BASE_TYPE}
ARG TEST_WITH_DARWIN=false

# build prepares the sources
FROM --platform=$BUILDPLATFORM alpine AS build
COPY xx-* /out/
RUN ln -s xx-cc /out/xx-clang && \
    ln -s xx-cc /out/xx-clang++ && \
    ln -s xx-cc /out/xx-c++ && \
    ln -s xx-apt /out/xx-apt-get

# xx builds the xx image
FROM scratch AS xx
COPY --from=build /out/ /usr/bin/

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS bats-assert

FROM ${TEST_BASE_IMAGE} AS test-base-alpine
RUN --mount=type=cache,target=/pkg-cache \
    ln -s /pkg-cache /etc/apk/cache && \
    apk add bats vim
WORKDIR /work

FROM ${TEST_BASE_IMAGE} AS test-base-debian
ARG APT_MIRROR=deb.debian.org
RUN --mount=type=cache,target=/pkg-cache \
    rm -rf /var/cache/apt/archives && \
    ln -s /pkg-cache /var/cache/apt/archives && \
    rm /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "1";' > /etc/apt/apt.conf.d/keep-downloads && \
    touch /etc/apt/sources.list && \
    sed -ri "s/(httpredir|deb).debian.org/${APT_MIRROR:-deb.debian.org}/g" /etc/apt/sources.list && \
    sed -ri "s/(security).debian.org/${APT_MIRROR:-security.debian.org}/g" /etc/apt/sources.list && \
    apt update && apt install --no-install-recommends -y bats vim
WORKDIR /work

FROM ${TEST_BASE_IMAGE} AS test-base-rhel
RUN <<EOT
set -ex
if ! yum install -y epel-release; then
  if . /etc/os-release 2>/dev/null; then
    if [ "$ID" != "fedora" ]; then
      yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION:0:1}.noarch.rpm
    fi
  fi
fi
EOT
RUN --mount=type=cache,target=/pkg-cache \
    rm -rf /var/cache/yum && \
    ln -s /pkg-cache /var/cache/yum && \
    yum update -y && yum -y install bats vim
WORKDIR /work


FROM test-base-${TEST_BASE_TYPE} AS test-base
ADD --chmod=755 https://raw.githubusercontent.com/fsaintjacques/semver-tool/3.4.0/src/semver /usr/bin/semver
COPY --from=bats-assert . .
COPY --from=xx / /

FROM test-base AS test-base-fixtures
COPY fixtures fixtures

FROM test-base AS test-info
ARG TEST_BASE_TYPE
COPY test-info-common.bats test-info-${TEST_BASE_TYPE}.bats ./
RUN ./test-info-common.bats && ./test-info-${TEST_BASE_TYPE}.bats

FROM test-base AS test-windres
COPY test-windres.bats test_helper.bash ./
RUN --mount=type=cache,target=/pkg-cache,sharing=locked ./test-windres.bats

FROM test-base AS test-apt
COPY test-apt.bats .
RUN --mount=type=cache,target=/pkg-cache,sharing=locked [ ! -f /etc/debian_version ] || ./test-apt.bats

FROM test-base AS test-apk
COPY test-apk.bats .
RUN --mount=type=cache,target=/pkg-cache,sharing=locked [ ! -f /etc/alpine-release ] || ./test-apk.bats

FROM test-base AS test-verify
COPY test-verify.bats .
RUN --mount=type=cache,target=/pkg-cache,sharing=locked ./test-verify.bats

FROM test-base-fixtures AS test-clang
COPY test-clang.bats test_helper.bash ./
RUN --mount=type=cache,target=/pkg-cache,sharing=locked ./test-clang.bats

FROM test-base-fixtures AS test-go
COPY test-go.bats test_helper.bash ./
RUN --mount=type=cache,target=/pkg-cache,sharing=locked --mount=type=cache,target=/root/.cache ./test-go.bats

FROM test-base-fixtures AS test-cargo
COPY test-cargo.bats test_helper.bash ./
RUN --mount=type=cache,target=/pkg-cache,sharing=locked ./test-cargo.bats


FROM scratch AS sdk-extras

# dev can be used for debugging during development
FROM test-base AS dev
COPY --from=sdk-extras / /
COPY --from=xx / /
COPY fixtures fixtures
COPY *.bats test_helper.bash ./

# default is alias to build xx image
FROM xx as default