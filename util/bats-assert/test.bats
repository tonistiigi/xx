#!/usr/bin/env bats

load 'assert'

@test "failing" {
  assert_equal "foo" "bar"
}

@test "run-no-success" {
  run echo "start" && false
  assert_failure
}

@test "run foobar" {
  run ./foobar
  assert_failure
}

@test "run" {
  run echo "abc"
  assert_success
  assert_output "abc"
}

@test "run-fail" {
  run echo "abc"
  assert_success
  assert_output "bcd"
}
