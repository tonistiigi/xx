#!/usr/bin/env bats

load 'assert'

@test "nogo" {
  apk del go 2>/dev/null || true
  run xx-go env
  assert_failure
  assert_output --partial "go: not found"
}

testEnv() {
  run xx-go env
  assert_success
  assert_output --partial 'GOARCH="'"$(xx-info arch)"'"'
  assert_output --partial 'GOOS="'"$(xx-info os)"'"'
  assert_output --partial 'GOHOSTOS="'"$(TARGETOS= TARGETARCH= xx-info os)"'"'
  assert_output --partial 'GOHOSTARCH="'"$(TARGETOS= TARGETARCH= xx-info arch)"'"'

  if [ $(xx-info arch) = "arm" ]; then
    assert_output --partial 'GOARM="'"$expArm"'"'
  fi
}

@test "native-env" {
  apk add go 2>/dev/null || true
  testEnv
}

@test "amd64-env" {
  export TARGETARCH=amd64
  testEnv
}

@test "arm64-env" {
  export TARGETARCH=arm64
  testEnv
}

@test "armv5-env" {
  export TARGETARCH=arm
  export TARGETVARIANT=v5
  expArm=5
  testEnv
  unset TARGETVARIANT
}

@test "arm-env" {
  export TARGETARCH=arm
  expArm=7
  testEnv
}

@test "armv6-env" {
  export TARGETARCH=arm
  export TARGETVARIANT=v6
  expArm=6
  testEnv
  unset TARGETVARIANT
}

@test "armv7-env" {
  export TARGETARCH=arm
  export TARGETVARIANT=v7
  expArm=7
  testEnv
  unset TARGETVARIANT
}

@test "riscv64-env" {
  export TARGETARCH=riscv64
  testEnv
}

@test "s390x-env" {
  export TARGETARCH=s390x
  testEnv
}

@test "ppc64le-env" {
  export TARGETARCH=ppc64le
  testEnv
}

@test "darwin-amd64-env" {
  export TARGETOS=darwin
  export TARGETARCH=amd64
  testEnv
}

@test "darwin-arm64-env" {
  export TARGETOS=darwin
  export TARGETARCH=arm64
  testEnv
  unset TARGETOS
}

testHelloGO() {
  run xx-go build -o /tmp/a.out ./fixtures/hello.go
  assert_success
  xx-verify /tmp/a.out
  if ! xx-info is-cross; then
    run /tmp/a.out
    assert_success
    assert_output "hello go"
  fi
}

@test "native-hellogo" {
  unset TARGETARCH
  testHelloGO
}

@test "amd64-hellogo" {
  export TARGETARCH=amd64
  testHelloGO
}

@test "arm64-hellogo" {
  export TARGETARCH=arm64
  testHelloGO
}

@test "arm-hellogo" {
  export TARGETARCH=arm
  testHelloGO
}

@test "armv5-hellogo" {
  export TARGETARCH=arm
  export TARGETVARIANT=v5
  testHelloGO
  unset TARGETVARIANT
}

@test "s390x-hellogo" {
  export TARGETARCH=s390x
  testHelloGO
}

@test "ppc64le-hellogo" {
  export TARGETARCH=ppc64le
  testHelloGO
}

@test "386-hellogo" {
  export TARGETARCH=386
  testHelloGO
}

testHelloCGO() {
  export CGO_ENABLED=1
  xx-apk add musl-dev gcc
  run xx-go build -x -o /tmp/a.out ./fixtures/hello_cgo.go
  assert_success
  xx-verify /tmp/a.out
  if ! xx-info is-cross; then
    run /tmp/a.out
    assert_success
    assert_output "hello cgo"
  fi
}

@test "native-hellocgo" {
  apk add clang lld
  unset TARGETARCH
  testHelloCGO
}

@test "amd64-hellocgo" {
  export TARGETARCH=amd64
  testHelloCGO
}

@test "arm64-hellocgo" {
  export TARGETARCH=arm64
  testHelloCGO
}

@test "arm-hellocgo" {
  export TARGETARCH=arm
  testHelloCGO
}

@test "ppc64le-hellocgo" {
  export TARGETARCH=ppc64le
  testHelloCGO
}

@test "386-hellocgo" {
  export TARGETARCH=386
  testHelloCGO
}

@test "wrap-unwrap" {
  target="arm64"
  if [ "$(xx-info arch)" = "arm64" ]; then target="amd64"; fi
  export TARGETARCH=$target

  nativeArch=$(TARGETARCH= xx-info arch)
  
  run go env GOARCH
  assert_success
  assert_output "$nativeArch"

  run xx-go --wrap
  assert_success

  run go env GOARCH
  assert_success
  assert_output "$target"

  run xx-go --unwrap

  run go env GOARCH
  assert_success
  assert_output "$nativeArch"
}
