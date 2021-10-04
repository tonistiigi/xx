#!/usr/bin/env bats

load 'assert'

@test "native" {
  run xx-verify /bin/ls
  assert_success
}

@test "flags" {
  run xx-verify
  assert_failure
  assert_output --partial "Usage"

  run xx-verify --setup
  assert_success

  run xx-verify --static
  assert_failure
  assert_output --partial "Usage"

  run xx-verify --static2
  assert_failure
  assert_output --partial "invalid flag"

  run xx-verify --static /bin/ls
  assert_failure
  assert_output --partial "not statically linked"
}

@test "static" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped"
  export TARGETPLATFORM=linux/arm64
  run xx-verify --static /idontexist
  assert_failure
  assert_output --partial "not statically linked"

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, with debug_info, not stripped"
  export TARGETPLATFORM=linux/amd64
  run xx-verify --static /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), static-pie linked, with debug_info, not stripped"
  run xx-verify --static /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped"
  export TARGETPLATFORM=linux/arm64
  run xx-verify --static /idontexist
  assert_success

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}
