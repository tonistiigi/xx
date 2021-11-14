#!/usr/bin/env bats

load "assert"

@test "vendor" {
  assert_equal "fedora" "$(xx-info vendor)"
}

@test "rhel-arch" {
  assert_equal "$(xx-info rhel-arch)" "$(xx-info pkg-arch)"
}

@test "amd64" {
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64 xx-info pkg-arch)"
}

@test "aarch64" {
  assert_equal "aarch64" "$(TARGETPLATFORM=linux/arm64 xx-info pkg-arch)"
}

@test "arm" {
  assert_equal "armv7hl" "$(TARGETPLATFORM=linux/arm xx-info pkg-arch)"
}

@test "armv6" {
  assert_equal "armv6hl" "$(TARGETPLATFORM=linux/arm/v6 xx-info pkg-arch)"
}

@test "armv5" {
  assert_equal "armv5tel" "$(TARGETPLATFORM=linux/arm/v5 xx-info pkg-arch)"
}

@test "386" {
  assert_equal "i386" "$(TARGETPLATFORM=linux/386 xx-info pkg-arch)"
}

@test "ppc64le" {
  assert_equal "ppc64le" "$(TARGETPLATFORM=linux/ppc64le xx-info pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info pkg-arch)"
}
