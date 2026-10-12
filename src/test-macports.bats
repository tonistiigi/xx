#!/usr/bin/env bats

load 'assert'
load 'test_helper'

@test "install" {
  add openssl wget
  assert_success

  export TARGETOS=darwin
  run xx-macports --static install jq
  assert_success
  assert_output --partial "installed jq"
  run test -e "${OSXCROSS_TARGET_DIR}/macports/pkgs/opt/local/bin/jq"
}
