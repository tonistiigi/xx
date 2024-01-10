#!/usr/bin/env bats

load 'assert'

@test "no_cmd" {
  run xx-apt
  assert_failure
  assert_output --partial "Usage: apt"
}

@test "native" {
  run xx-apt show file
  assert_success
  assert_line "Package: file"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev"

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc"
}

@test "essentials" {
  run xx-apt show xx-c-essentials
  assert_success

  run xx-apt show xx-cxx-essentials
  assert_success
}

@test "amd64" {
  export TARGETARCH=amd64
  if ! xx-info is-cross; then skip; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:amd64"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:amd64"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-amd64-cross"
  unset XX_APT_PREFER_CROSS

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-x86-64-linux-gnu"
}

@test "arm64" {
  export TARGETARCH=arm64
  if ! xx-info is-cross; then return; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:arm64"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:arm64"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-arm64-cross"
  unset XX_APT_PREFER_CROSS

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-aarch64-linux-gnu"
}

@test "arm" {
  export TARGETARCH=arm
  if ! xx-info is-cross; then return; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:armhf"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:armhf"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-armhf-cross"
  unset XX_APT_PREFER_CROSS

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-arm-linux-gnueabihf"
}

@test "armv6" {
  export TARGETARCH=arm
  export TARGETVARIANT=v6
  if ! xx-info is-cross; then return; fi
  if [ "$(xx-info vendor)" = "ubuntu" ]; then skip; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:armel"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:armel"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-armel-cross"
  unset XX_APT_PREFER_CROSS

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-arm-linux-gnueabi"
  unset TARGETVARIANT
}

@test "s390x" {
  export TARGETARCH=s390x
  if ! xx-info is-cross; then return; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:s390x"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:s390x"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-s390x-cross"
  unset XX_APT_PREFER_CROSS

  # buster has no gcc package for arm64
  if [ "$(uname -m)" == "aarch64" ] && [ "$(cat /etc/debian_version | cut -d. -f 1)" = "10" ]; then
    return
  fi

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-s390x-linux-gnu"
}

@test "ppc64le" {
  export TARGETARCH=ppc64le
  if ! xx-info is-cross; then return; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:ppc64el"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:ppc64el"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-ppc64el-cross"
  unset XX_APT_PREFER_CROSS

  # buster has no gcc package for arm64
  if [ "$(uname -m)" == "aarch64" ] && [ "$(cat /etc/debian_version | cut -d. -f 1)" = "10" ]; then
    return
  fi

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-powerpc64le-linux-gnu"
}

@test "386" {
  export TARGETARCH=386
  if ! xx-info is-cross; then return; fi

  run xx-apt show file
  assert_success
  assert_line "Package: file:i386"

  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev:i386"

  export XX_APT_PREFER_CROSS=1
  run xx-apt show libc6-dev
  assert_success
  assert_line "Package: libc6-dev-i386-cross"
  unset XX_APT_PREFER_CROSS

  run xx-apt show gcc
  assert_success
  assert_line "Package: gcc-i686-linux-gnu"
}

@test "skip-nolinux" {
  export TARGETOS="darwin"
  export TARGETARCH="amd64"
  run xx-apt install foo
  assert_success
  unset TARGETOS
  unset TARGETARCH
}

@test "checkpkg" {
  run apt show wget
  assert_success
  run apt show wget-notexist
  assert_failure
}

@test "print-source-file" {
  run xx-apt --print-source-file
  assert_success
  assert_output --partial "/etc/apt/sources.list"

  run test -e "$(xx-apt --print-source-file)"
  assert_success
}
