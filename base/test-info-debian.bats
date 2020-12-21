#!/usr/bin/env bats

load "assert"

@test "vendor" {
  assert_equal "debian" "$(xx-info vendor)"
}

@test "libc" {
  assert_equal "gnu" "$(xx-info libc)"
  assert_equal "musl" "$(XX_LIBC=musl xx-info libc)"
}

@test "debian-arch" {
  assert_equal "$(xx-info debian-arch)" "$(xx-info pkg-arch)"
}

@test "aarch64" {
  assert_equal "aarch64-linux-gnu" "$(TARGETPLATFORM=linux/arm64 xx-info triple)"
  assert_equal "arm64" "$(TARGETPLATFORM=linux/arm64 xx-info pkg-arch)"
}

@test "arm" {
  assert_equal "arm-linux-gnueabihf" "$(TARGETPLATFORM=linux/arm xx-info triple)"
  assert_equal "armhf" "$(TARGETPLATFORM=linux/arm xx-info pkg-arch)"
}

@test "armv6" {
  assert_equal "arm-linux-gnueabi" "$(TARGETPLATFORM=linux/arm/v6 xx-info triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v6 xx-info pkg-arch)"
}

@test "armv5" {
  assert_equal "arm-linux-gnueabi" "$(TARGETPLATFORM=linux/arm/v5 xx-info triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v5 xx-info pkg-arch)"
}

@test "386" {
  assert_equal "i586-linux-gnu" "$(TARGETPLATFORM=linux/386 xx-info triple)"
  assert_equal "i386" "$(TARGETPLATFORM=linux/386 xx-info pkg-arch)"
}

@test "ppc64le" {
  assert_equal "powerpc64le-linux-gnu" "$(TARGETPLATFORM=linux/ppc64le xx-info triple)"
  assert_equal "ppc64el" "$(TARGETPLATFORM=linux/ppc64le xx-info pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x-linux-gnu" "$(TARGETPLATFORM=linux/s390x xx-info triple)"
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64-linux-gnu" "$(TARGETPLATFORM=linux/riscv64 xx-info triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info pkg-arch)"
}
