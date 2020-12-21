#!/usr/bin/env bats

load 'assert'

@test "no_cmd" {
  run xx-apk
  assert_failure
  assert_output --partial "apk-tools"
}

@test "list-native" {
  run xx-apk list
  assert_success
  assert_output --partial "busybox"
  assert_output --partial "alpine-baselayout"
}

@test "cross" {
  target="arm64"
  if [ "$(xx-info arch)" = "arm64" ]; then target="amd64"; fi
  export TARGETARCH=$target
  [ ! -d "/$(xx-info)" ]
  run xx-apk list
  assert_success
  assert_output --partial "alpine-keys"
  refute_output --partial "alpine-baselayout"
  [ -d "/$(xx-info)" ]
  run cat /$(xx-info)/etc/apk/arch
  assert_output "$(xx-info alpine-arch)"
  run xx-apk add --no-cache zlib
  assert_success
  [ -f "/$(xx-info)/lib/libz.so.1" ]
  run xx-apk del zlib
  assert_success
  [ ! -f "/$(xx-info)/lib/libz.so.1" ]
  run xx-apk clean
  assert_success
  [ ! -d "/$(xx-info)" ]
  unset TARGETARCH
}
