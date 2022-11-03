#!/usr/bin/env bats

load 'assert'
load 'test_helper'

cleanPackages() {
  for p in linux/amd64 linux/arm64 linux/ppc64le linux/s390x linux/386 linux/arm/v7 linux/arm/v6; do
    TARGETPLATFORM=$p xxdel xx-c-essentials
    root=/$(TARGETPLATFORM=$p xx-info triple)
    if [ -d "$root" ] && [ "$root" != "/" ]; then
      rm -rf "$root"
    fi
  done
  del cargo rust
  del pkgconfig || del pkg-config
  rm -rf "$HOME/.cargo" /.xx-cargo* || true
}

@test "nocargo" {
  cleanPackages
  add clang
  run xx-cargo --version
  assert_failure
  assert_output --partial "cargo: not found"
}

testHelloCargo() {
  rm -f "/.xx-cargo.$(xx-info arch)"
  run xxadd xx-c-essentials
  assert_success
  run xx-cargo build --verbose --color=never --manifest-path=./fixtures/hello_cargo/Cargo.toml --release --target-dir /tmp/cargobuild
  assert_success
  xx-verify /tmp/cargobuild/$(xx-cargo --print-target)/release/hello_cargo
  if ! xx-info is-cross; then
    run /tmp/cargobuild/$(xx-cargo --print-target)/release/hello_cargo
    assert_success
    assert_output "hello cargo"
  fi
  rm -rf /tmp/cargobuild
}

testHelloCargoRustup() {
  export PATH="$HOME/.cargo/bin:$PATH"
  testHelloCargo
}

@test "install-rustup" {
  add clang lld curl ca-certificates
  assert_success
  run sh -c "curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --no-modify-path --profile minimal"
  assert_success
}

@test "amd64-hellocargo-rustup" {
  export TARGETARCH=amd64
  testHelloCargoRustup
}

@test "arm64-hellocargo-rustup" {
  export TARGETARCH=arm64
  testHelloCargoRustup
}

@test "arm-hellocargo-rustup" {
  export TARGETARCH=arm
  testHelloCargoRustup
}

@test "ppc64le-hellocargo-rustup" {
  if [ -f /etc/alpine-release ]; then
    skip "rust stdlib not yet available for powerpc64le-unknown-linux-musl"
  fi
  export TARGETARCH=ppc64le
  testHelloCargoRustup
}

@test "riscv64-hellocargo-rustup" {
  if ! supportRiscVCGo; then
    skip "RISC-V not supported" # rust stdlib package not available
  fi
  export TARGETARCH=riscv64
  testHelloCargoRustup
}

@test "386-hellocargo-rustup" {
  export TARGETARCH=386
  testHelloCargoRustup
}

@test "uninstall-rustup" {
  export PATH="$HOME/.cargo/bin:$PATH"
  rustup self uninstall -y
}

@test "install-rustpkg" {
  cleanPackages
  add clang lld
  case "$(xx-info vendor)" in
    alpine)
      add cargo rust
      ;;
    debian | ubuntu)
      add cargo
      ;;
  esac
}

@test "amd64-hellocargo-rustpkg" {
  export TARGETARCH=amd64
  testHelloCargo
}

@test "arm64-hellocargo-rustpkg" {
  export TARGETARCH=arm64
  testHelloCargo
}

@test "arm-hellocargo-rustpkg" {
  export TARGETARCH=arm
  testHelloCargo
}

@test "ppc64le-hellocargo-rustpkg" {
  export TARGETARCH=ppc64le
  testHelloCargo
}

@test "riscv64-hellocargo-rustpkg" {
  if ! supportRiscVCGo; then
    skip "RISC-V not supported" # rust stdlib package not available
  fi
  export TARGETARCH=riscv64
  export RISCV64_TARGET_ARCH=riscv64
  testHelloCargo
}

@test "386-hellocargo-rustpkg" {
  export TARGETARCH=386
  testHelloCargo
}

@test "clean-packages" {
  cleanPackages
}
