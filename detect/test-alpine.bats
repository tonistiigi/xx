#!/usr/bin/env bats

@test "vendor" {
  result="$(xx-detect vendor)"
  [ "$result" = "alpine" ]
}

@test "libc" {
  result="$(xx-detect libc)"
  echo $result
  [ "$result" = "musl" ]
  result="$(XX_LIBC=gnu xx-detect libc)"
  [ "$result" = "gnu" ]
}

@test "arch os filled" {
  result="$(xx-detect march)"
  [ "$result" = "$(uname -m)" ]
  result="$(xx-detect os)"
  [ "$result" = "linux" ]
}

@test "is-cross" {
  run xx-detect is-cross
  [ "$status" -eq 1 ]
  if [ "$(uname -m)" != "x86_64" ]; then
    echo "here2"
    run TARGETARCH=amd64 xx-detect is-cross
  else
    run TARGETARCH=arm64 xx-detect is-cross
  fi
  [ "$status" -eq 0 ]
}

@test "invalid-command" {
  run xx-detect something
  [ "$status" -eq 1 ]
}
