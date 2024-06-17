#!/usr/bin/env bats

load 'assert'

@test "no_cmd" {
  run xx-dnf
  assert_output --partial "usage: dnf [options] COMMAND"
}

@test "native" {
  run xx-dnf info file
  assert_success
  assert_line "Name         : file"

  run xx-dnf info glibc-devel
  assert_success
  assert_line "Name         : glibc-devel"

  run xx-dnf info gcc
  assert_success
  assert_line "Name         : gcc"
}

@test "essentials" {
  run xx-dnf info xx-c-essentials
  assert_success

  run xx-dnf info xx-cxx-essentials
  assert_success
}

@test "amd64" {
  export TARGETARCH=amd64
  if ! xx-info is-cross; then skip; fi

  run xx-dnf info file
  assert_success
  assert_line "Architecture : x86_64"

  run xx-dnf info glibc-devel
  assert_success
  assert_line "Architecture : x86_64"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info glibc-devel
  assert_success
  assert_line "Package: glibc-devel-amd64-cross"
  unset XX_dnf_PREFER_CROSS

  run xx-dnf info gcc
  assert_success
  assert_line "Architecture : x86_64"
}

@test "arm64" {
  export TARGETARCH=arm64
  if ! xx-info is-cross; then return; fi

  run xx-dnf info file
  assert_success
  assert_line "Architecture : aarch64"

  run xx-dnf info glibc-devel
  assert_success
  assert_line "Architecture : aarch64"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info glibc-devel
  assert_success
  assert_line "Name: glibc-devel-arm64-cross"
  unset XX_dnf_PREFER_CROSS

  run xx-dnf info gcc
  assert_success
  assert_line "Architecture : aarch64"
}

@test "arm" {
  export TARGETARCH=arm
  if ! xx-info is-cross; then return; fi

  run xx-dnf info file
  assert_success
  assert_line "Package: file:armhf"

  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev:armhf"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev-armhf-cross"
  unset XX_dnf_PREFER_CROSS

  run xx-dnf info gcc
  assert_success
  assert_line "Package: gcc-arm-linux-gnueabihf"
}

@test "armv6" {
  export TARGETARCH=arm
  export TARGETVARIANT=v6
  if ! xx-info is-cross; then return; fi
  if [ "$(xx-info vendor)" = "ubuntu" ]; then skip; fi

  run xx-dnf info file
  assert_success
  assert_line "Package: file:armel"

  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev:armel"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev-armel-cross"
  unset XX_dnf_PREFER_CROSS

  run xx-dnf info gcc
  assert_success
  assert_line "Package: gcc-arm-linux-gnueabi"
  unset TARGETVARIANT
}

@test "s390x" {
  export TARGETARCH=s390x
  if ! xx-info is-cross; then return; fi

  run xx-dnf info file
  assert_success
  assert_line "Package: file:s390x"

  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev:s390x"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev-s390x-cross"
  unset XX_dnf_PREFER_CROSS

  run xx-dnf info gcc
  assert_success
  assert_line "Package: gcc-s390x-linux-gnu"
}

@test "ppc64le" {
  export TARGETARCH=ppc64le
  if ! xx-info is-cross; then return; fi

  run xx-dnf info file
  assert_success
  assert_line "Package: file:ppc64le"

  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev:ppc64le"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev-ppc64le-cross"
  unset XX_dnf_PREFER_CROSS

  # buster has no gcc package for arm64
  if [ "$(uname -m)" == "aarch64" ] && [ "$(cat /etc/debian_version | cut -d. -f 1)" = "10" ]; then
    return
  fi

  run xx-dnf info gcc
  assert_success
  assert_line "Package: gcc-powerpc64le-linux-gnu"
}

@test "386" {
  export TARGETARCH=386
  if ! xx-info is-cross; then return; fi

  run xx-dnf info file
  assert_success
  assert_line "Package: file:i386"

  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev:i386"

  export XX_dnf_PREFER_CROSS=1
  run xx-dnf info libc6-dev
  assert_success
  assert_line "Package: libc6-dev-i386-cross"
  unset XX_dnf_PREFER_CROSS

  run xx-dnf info gcc
  assert_success
  assert_line "Package: gcc-i686-linux-gnu"
}

@test "skip-nolinux" {
  export TARGETOS="darwin"
  export TARGETARCH="amd64"
  run xx-dnf install foo
  assert_success
  unset TARGETOS
  unset TARGETARCH
}

@test "checkpkg" {
  run dnf info wget2
  assert_success
  run dnf info wget2-notexist
  assert_failure
}
