#!/usr/bin/env bats

load 'assert'

@test "arch os filled" {
  assert_equal "$(uname -m)" "$(xx-info march)"
  assert_equal "linux" "$(xx-info os)"
}

@test "is-cross" {
  run xx-info is-cross
  assert_failure
  if [ "$(uname -m)" != "x86_64" ]; then
    TARGETARCH=amd64 run xx-info is-cross
  else
    TARGETARCH=arm64 run xx-info is-cross
  fi
  assert_success
  TARGETARCH=$(xx-info arch) run xx-info is-cross
  assert_failure
}

@test "parse platform" {
  TARGETPLATFORM=foo/bar run xx-info os
  assert_success
  assert_output "foo"

  TARGETPLATFORM=foo/bar run xx-info arch
  assert_success
  assert_output "bar"
}

@test "default arm variant" {
  assert_equal "" "$(TARGETARCH=amd64 xx-info variant)"
  assert_equal "v7" "$(TARGETARCH=arm xx-info variant)"
}

@test "invalid-command" {
  run xx-info something
  assert_failure
}

@test "aarch64" {
  assert_equal "aarch64" "$(TARGETPLATFORM=linux/arm64 xx-info march)"
}

@test "arm" {
  assert_equal "armv7l" "$(TARGETPLATFORM=linux/arm xx-info march)"
}

@test "armv6" {
  assert_equal "armv6l" "$(TARGETPLATFORM=linux/arm/v6 xx-info march)"
}

@test "armv5" {
  assert_equal "armv5l" "$(TARGETPLATFORM=linux/arm/v5 xx-info march)"
}

@test "amd64" {
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64 xx-info march)"
}

@test "386" {
  assert_equal "i386" "$(TARGETPLATFORM=linux/386 xx-info march)"
}

@test "riscv64" {
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info march)"
}

@test "s390x" {
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info march)"
}

@test "ppc64le" {
  assert_equal "ppc64le" "$(TARGETPLATFORM=linux/ppc64le xx-info march)"
}
