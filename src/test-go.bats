#!/usr/bin/env bats

load 'assert'
load 'test_helper'

ensureGo() {
  if command -v apk >/dev/null 2>/dev/null; then
    add go
  else
    add golang
  fi
  if [ "$(xx-info arch)" = "loong64" ]; then
    add clang binutils
  else
    add clang lld
  fi
}

setup_file() {
  ensureGo
}

teardown_file() {
  for p in linux/amd64 linux/arm64 linux/ppc64le linux/s390x linux/386 linux/arm/v7 linux/arm/v6 linux/riscv64 linux/loong64; do
    TARGETPLATFORM=$p xxdel xx-c-essentials
    root=/$(TARGETPLATFORM=$p xx-info triple)
    if [ -d "$root" ] && [ "$root" != "/" ]; then
      rm -rf "$root"
    fi
  done
  del clang lld llvm
  del pkgconfig || del pkg-config
  if command -v apk >/dev/null 2>/dev/null; then
    del go
  else
    del golang
  fi
  rm /tmp/a.out || true
  rm -rf /var/cache/apt/*.bin || true
}

testEnv() {
  # single/double quotes changed in between go versions
  run sh -c "xx-go env | sed 's/[\"'\'']//g'"
  assert_success
  assert_output --partial "GOARCH=$(xx-info arch)"
  assert_output --partial "GOOS=$(xx-info os)"
  assert_output --partial "GOHOSTOS=$(TARGETOS= TARGETARCH= xx-info os)"
  assert_output --partial "GOHOSTARCH=$(TARGETOS= TARGETARCH= xx-info arch)"

  case "$(xx-info arch)" in
    "arm")
      assert_output --partial "GOARM=$expArm"
      ;;
    "mips64"*)
      assert_output --partial "GOMIPS64=$expMips"
      ;;
    "mips"*)
      assert_output --partial "GOMIPS=$expMips"
      ;;
  esac
}

@test "nogo" {
  if command -v apk >/dev/null 2>/dev/null; then
    del go
  else
    del golang
  fi
  run xx-go env
  assert_failure
  assert_output --partial "go: not found"
  ensureGo
}

@test "native-env" {
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

@test "loong64-env" {
  if ! supportLoongArchGo; then
    skip "LoongArch64 GO not supported"
  fi
  export TARGETARCH=loong64
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

@test "mips-env" {
  export TARGETARCH=mips
  expMips=hardfloat
  testEnv
}

@test "mips-softfloat-env" {
  export TARGETARCH=mips
  export TARGETVARIANT=softfloat
  expMips=softfloat
  testEnv
  unset TARGETVARIANT
}

@test "mipsle-env" {
  export TARGETARCH=mipsle
  expMips=hardfloat
  testEnv
}

@test "mipsle-softfloat-env" {
  export TARGETARCH=mipsle
  export TARGETVARIANT=softfloat
  expMips=softfloat
  testEnv
  unset TARGETVARIANT
}

@test "mips64-env" {
  export TARGETARCH=mips64
  expMips=hardfloat
  testEnv
}

@test "mips64-softfloat-env" {
  export TARGETARCH=mips64
  export TARGETVARIANT=softfloat
  expMips=softfloat
  testEnv
  unset TARGETVARIANT
}

@test "mips64le-env" {
  export TARGETARCH=mips64le
  expMips=hardfloat
  testEnv
}

@test "mips64le-softfloat-env" {
  export TARGETARCH=mips64le
  export TARGETVARIANT=softfloat
  expMips=softfloat
  testEnv
  unset TARGETVARIANT
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

@test "riscv64-hellogo" {
  if ! supportRiscVGo; then
    skip "RISC-V GO not supported"
  fi
  export TARGETARCH=riscv64
  testHelloGO
}

@test "loong64-hellogo" {
  if ! supportLoongArchGo; then
    skip "LoongGArch64 GO not supported"
  fi
  export TARGETARCH=loong64
  testHelloGO
}

@test "386-hellogo" {
  export TARGETARCH=386
  testHelloGO
}

@test "mipsle-hellogo" {
  export TARGETARCH=mipsle
  testHelloGO
}

@test "mipsle-softfloat-hellogo" {
  export TARGETARCH=mipsle
  export TARGETVARIANT=softfloat
  testHelloGO
  unset TARGETVARIANT
}

@test "mips64le-hellogo" {
  export TARGETARCH=mips64le
  testHelloGO
}

@test "mips64le-softfloat-hellogo" {
  export TARGETARCH=mips64le
  export TARGETVARIANT=softfloat
  testHelloGO
  unset TARGETVARIANT
}

@test "darwin-amd64-hellogo" {
  export TARGETARCH=amd64
  export TARGETOS=darwin
  testHelloGO
}

testHelloCGO() {
  export CGO_ENABLED=1
  xxadd xx-c-essentials
  run xx-go build -x -o /tmp/a.out ./fixtures/hello_cgo.go
  assert_success
  run xx-verify /tmp/a.out
  assert_success
  if ! xx-info is-cross; then
    run /tmp/a.out
    assert_success
    assert_output "hello cgo"
  fi
}

@test "native-hellocgo" {
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

@test "riscv64-hellocgo" {
  if ! supportRiscVCGo; then
    skip "RISC-V CGO not supported"
  fi
  export TARGETARCH=riscv64
  testHelloCGO
}

@test "loong64-hellocgo" {
  skip "LOONG64 CGO not supported"
}

@test "386-hellocgo" {
  export TARGETARCH=386
  testHelloCGO
}

@test "arm64-cgoenv" {
  export TARGETARCH=arm64
  export CGO_ENABLED=1
  rm /usr/bin/$(xx-info triple).cfg || true
  rm /etc/llvm/xx-default.cfg || true
  rm -rf /usr/bin/$(xx-info triple)* || true

  add llvm
  add pkgconf || add pkg-config
  xxadd xx-c-essentials
  xxadd pkgconf || add pkg-config
  # single/double quotes changed in between go versions
  run sh -c "xx-go env | sed 's/[\"'\'']//g'"
  assert_success
  assert_output --partial "CC=$(xx-info triple)-clang"
  assert_output --partial "CXX=$(xx-info triple)-clang++"
  assert_output --partial "AR=$(xx-info triple)-ar"
  assert_output --partial "PKG_CONFIG=$(xx-info triple)-pkg-config"
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
