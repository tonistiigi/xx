#!/usr/bin/env bats

load 'assert'

@test "vendor" {
  assert_equal "alpine" "$(xx-info vendor)"
}

@test "libc" {
  assert_equal "musl" "$(xx-info libc)"
  assert_equal "gnu" "$(XX_LIBC=gnu xx-info libc)"
}

@test "libc-override" {
  assert_equal "aarch64-alpine-linux-gnu" "$(TARGETPLATFORM=linux/arm64 XX_LIBC=gnu xx-info triple)"
}

@test "alpine-arch" {
  assert_equal "$(xx-info alpine-arch)" "$(xx-info pkg-arch)"
}

@test "aarch64" {
  assert_equal "aarch64-alpine-linux-musl" "$(TARGETPLATFORM=linux/arm64 xx-info triple)"
  assert_equal "aarch64" "$(TARGETPLATFORM=linux/arm64 xx-info pkg-arch)"
}

@test "arm" {
  assert_equal "armv7-alpine-linux-musleabihf" "$(TARGETPLATFORM=linux/arm xx-info triple)"
  assert_equal "armv7" "$(TARGETPLATFORM=linux/arm xx-info pkg-arch)"
}

@test "armv6" {
  assert_equal "armv6-alpine-linux-musleabihf" "$(TARGETPLATFORM=linux/arm/v6 xx-info triple)"
  assert_equal "armhf" "$(TARGETPLATFORM=linux/arm/v6 xx-info pkg-arch)"
}

@test "386" {
  assert_equal "i586-alpine-linux-musl" "$(TARGETPLATFORM=linux/386 xx-info triple)"
  assert_equal "x86" "$(TARGETPLATFORM=linux/386 xx-info pkg-arch)"
}

@test "ppc64le" {
  assert_equal "powerpc64le-alpine-linux-musl" "$(TARGETPLATFORM=linux/ppc64le xx-info triple)"
  assert_equal "ppc64le" "$(TARGETPLATFORM=linux/ppc64le xx-info pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x-alpine-linux-musl" "$(TARGETPLATFORM=linux/s390x xx-info triple)"
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64-alpine-linux-musl" "$(TARGETPLATFORM=linux/riscv64 xx-info triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info pkg-arch)"
}
