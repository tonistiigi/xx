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
    ln -s xx-apt /out/xx-apt-get && \
    ln -s xx-dnf /out/xx-yum && \
    ln -s xx-dnf /out/xx-microdnf && \
    ln -s xx-dnf /out/xx-dnf5 && \
    ln -s xx-dnf /out/xx-dnf4 && \
    ln -s xx-dnf /out/xx-dnf-3

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
RUN --mount=type=cache,target=/pkg-cache \
    rm -rf /var/cache/apt/archives && \
    ln -s /pkg-cache /var/cache/apt/archives && \
    rm /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "1";' > /etc/apt/apt.conf.d/keep-downloads && \
    apt update && apt install --no-install-recommends -y bats vim
WORKDIR /work

FROM ${TEST_BASE_IMAGE} AS test-base-rhel
RUN --mount=type=cache,target=/pkg-cache <<EOT
set -ex

if test -e /etc/os-release; then
  . /etc/os-release
fi

if test -d /var/cache/yum; then
  rm -rf /var/cache/yum
  ln -s /pkg-cache /var/cache/yum
fi

if test -d /var/cache/dnf; then
  rm -rf /var/cache/dnf
  ln -s /pkg-cache /var/cache/dnf
fi

case "${ID}" in
  centos)
    sed 's/keepcache=0/keepcache=1/g' /etc/yum.conf
    ;;
  *)
    echo 'keepcache=True' >> /etc/dnf/dnf.conf
    ;;
esac

cmd_exists() {
  command -v $1 >/dev/null 2>/dev/null
}

get_dnf() {
  if cmd_exists dnf; then
    echo dnf
  elif cmd_exists yum; then
    echo yum
  elif cmd_exists dnf5; then
    echo dnf5
  elif cmd_exists dnf4; then
    echo dnf4
  elif cmd_exists dnf-3; then
    echo dnf-3
  elif cmd_exists microdnf; then
    echo microdnf
  else
    echo "No supported package manager found"
    exit 1
  fi
}

arg0="$(get_dnf)"

$arg0 makecache || true

if ! $arg0 install -y epel-release; then
  if . /etc/os-release 2>/dev/null; then
    case "$ID" in
      fedora|rocky) ;;
      *)
        $arg0 install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION:0:1}.noarch.rpm
        $arg0 update -y
        ;;
    esac
  fi
fi

$arg0 install -y bats vim
EOT
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

FROM test-base AS test-dnf
COPY test-dnf.bats .
RUN --mount=type=cache,target=/pkg-cache,sharing=locked [ ! -f /etc/system-release ] || ./test-dnf.bats

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


# these targets can be overwritten with build contexts
FROM scratch AS sdk-extras
FROM scratch AS ld64

# dev can be used for debugging during development
FROM test-base AS dev
COPY --link --from=sdk-extras / /
COPY --link --from=ld64 / /usr/bin/
COPY --link --from=xx / /
COPY fixtures fixtures
COPY *.bats test_helper.bash ./

# default is alias to build xx image
FROM xx as default
