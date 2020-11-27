#!/usr/bin/env bats

load "assert"

@test "vendor" {
  assert_equal "debian" "$(xx-detect vendor)"
}

@test "libc" {
  assert_equal "gnu" "$(xx-detect libc)"
  assert_equal "musl" "$(XX_LIBC=musl xx-detect libc)"
}

@test "debian-arch" {
  assert_equal "$(xx-detect debian-arch)" "$(xx-detect pkg-arch)"
}

@test "aarch64" {
  assert_equal "aarch64-linux-gnu" "$(TARGETPLATFORM=linux/arm64 xx-detect triple)"
  assert_equal "arm64" "$(TARGETPLATFORM=linux/arm64 xx-detect pkg-arch)"
}

@test "arm" {
  assert_equal "arm-linux-gnueabihf" "$(TARGETPLATFORM=linux/arm xx-detect triple)"
  assert_equal "armhf" "$(TARGETPLATFORM=linux/arm xx-detect pkg-arch)"
}

@test "armv6" {
  assert_equal "arm-linux-gnueabi" "$(TARGETPLATFORM=linux/arm/v6 xx-detect triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v6 xx-detect pkg-arch)"
}

@test "armv5" {
  assert_equal "arm-linux-gnueabi" "$(TARGETPLATFORM=linux/arm/v5 xx-detect triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v5 xx-detect pkg-arch)"
}

@test "386" {
  assert_equal "i586-linux-gnu" "$(TARGETPLATFORM=linux/386 xx-detect triple)"
  assert_equal "i386" "$(TARGETPLATFORM=linux/386 xx-detect pkg-arch)"
}

@test "ppc64le" {
  assert_equal "powerpc64le-linux-gnu" "$(TARGETPLATFORM=linux/ppc64le xx-detect triple)"
  assert_equal "ppc64el" "$(TARGETPLATFORM=linux/ppc64le xx-detect pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x-linux-gnu" "$(TARGETPLATFORM=linux/s390x xx-detect triple)"
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-detect pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64-linux-gnu" "$(TARGETPLATFORM=linux/riscv64 xx-detect triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-detect pkg-arch)"
}
