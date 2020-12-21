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
