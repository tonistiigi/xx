#!/usr/bin/env bats

load 'assert'

clean() {
  rm /etc/llvm/xx-default.cfg || true
  rm /usr/bin/*-alpine-*-clang || true
  rm /usr/bin/*-alpine-*-clang++ || true
  rm /usr/bin/*.cfg || true
}

testHelloCLLD() {
  clean
  apk add clang lld
  xx-apk add musl-dev gcc
  run xx-clang --print-target-triple
  assert_success
  assert_output $(xx-info triple)
  [ -f /etc/llvm/xx-default.cfg ]
  run cat /etc/llvm/xx-default.cfg
  assert_success
  assert_output "-fuse-ld=lld"
  [ -f /usr/bin/$(xx-info triple)-clang ]
  [ -f /usr/bin/$(xx-info triple)-clang++ ]
  [ -f /usr/bin/$(xx-info triple).cfg ]
  run cat /usr/bin/$(xx-info triple).cfg
  assert_success
  if ! xx-info is-cross; then
    assert_output "--target=$(xx-info triple) -fuse-ld=lld"
  else
    assert_output "--target=$(xx-info triple) -fuse-ld=lld --sysroot=/$(xx-info triple)/"
  fi
  testBuildHello
}

testHelloCPPLLD() {
  clean
  run xx-clang++ --print-target-triple
  assert_success
  assert_output $(xx-info triple)

  xx-apk add --no-cache g++
  clang++ --target=$(xx-clang++ --print-target-triple) -o /tmp/a.out fixtures/hello.cc
  xx-verify /tmp/a.out
  if ! xx-info is-cross; then
    run /tmp/a.out
    assert_success
    assert_output "hello c++"
  fi
}

testBuildHello() {
  clang --target=$(xx-clang --print-target-triple) -o /tmp/a.out fixtures/hello.c
  xx-verify /tmp/a.out
  if ! xx-info is-cross; then
    run /tmp/a.out
    assert_success
    assert_output "hello c"
  fi
}

@test "noclang" {
  apk del clang 2>/dev/null || true
  run xx-clang --print-target-triple
  assert_failure
  assert_output --partial "clang not found"
  [ ! -f /etc/llvm/xx-default.cfg ]
}

@test "nolinker" {
  apk del lld 2>/dev/null || true
  apk add clang
  run xx-clang --print-target-triple
  assert_failure
  assert_output --partial "no suitable linker"
  [ ! -f /etc/llvm/xx-default.cfg ]
}

@test "native-c" {
  unset TARGETARCH
  testHelloCLLD
}

@test "wrap-unwrap" {
  target="arm64"
  if [ "$(xx-info arch)" = "arm64" ]; then target="amd64"; fi
  export TARGETARCH=$target

  nativeTriple=$(TARGETARCH= xx-info triple)
  crossTriple=$(xx-info triple)

  [ "$nativeTriple" != "$crossTriple" ]

  run clang --print-target-triple
  assert_success
  assert_output "$nativeTriple"

  run xx-clang --print-target-triple
  assert_success
  assert_output "$crossTriple"

  run xx-clang --wrap
  assert_success

  run clang --print-target-triple
  assert_success
  assert_output "$crossTriple"

  run xx-clang --print-target-triple
  assert_success
  assert_output "$crossTriple"

  run xx-clang --unwrap
  assert_success

  run clang --print-target-triple
  assert_success
  assert_output "$nativeTriple"

  run xx-clang --print-target-triple
  assert_success
  assert_output "$crossTriple"
}

@test "native-c-ld" {
  clean
  apk del lld
  apk add binutils
  run xx-clang --print-target-triple
  assert_success
  assert_output $(xx-info triple)
  [ -f /etc/llvm/xx-default.cfg ]
  run cat /etc/llvm/xx-default.cfg
  assert_success
  assert_output "-fuse-ld=ld"
  [ -f /usr/bin/$(xx-info triple)-clang ]
  run /usr/bin/$(xx-info triple)-clang --print-target-triple
  assert_success
  assert_output $(xx-info triple)
  [ -f /usr/bin/$(xx-info triple)-clang++ ]
  [ -f /usr/bin/$(xx-info triple).cfg ]
  run cat /usr/bin/$(xx-info triple).cfg
  assert_success
  assert_output "--target=$(xx-info triple) -fuse-ld=ld"
  testBuildHello
  apk del binutils
}

@test "native-c++" {
  unset TARGETARCH
  testHelloCPPLLD
}

@test "amd64-c-lld" {
  export TARGETARCH=amd64
  testHelloCLLD
}

@test "arm64-c-lld" {
  export TARGETARCH=arm64
  testHelloCLLD
}

@test "armv6-c-lld" {
  export TARGETARCH=arm
  export TARGETVARIANT=v6
  testHelloCLLD
  unset TARGETVARIANT
}

@test "armv7-c-lld" {
  export TARGETARCH=arm
  testHelloCLLD
}

# ld.lld: error: unknown emulation: elf64_s390
# @test "s390x-c-lld" {
#   export TARGETARCH=s390x
#   testHelloCLLD
# }

@test "ppc64le-c-lld" {
  export TARGETARCH=ppc64le
  testHelloCLLD
}

@test "386-c-lld" {
  export TARGETARCH=386
  testHelloCPPLLD
}

@test "amd64-c++-lld" {
  export TARGETARCH=amd64
  testHelloCPPLLD
}

@test "arm64-c++-lld" {
  export TARGETARCH=arm64
  testHelloCPPLLD
}

@test "armv6-c++-lld" {
  export TARGETARCH=arm
  export TARGETVARIANT=v6
  testHelloCPPLLD
  unset TARGETVARIANT
}

@test "armv7-c++-lld" {
  export TARGETARCH=arm
  testHelloCPPLLD
}

@test "ppc64le-c++-lld" {
  export TARGETARCH=ppc64le
  testHelloCPPLLD
}

@test "386-c++-lld" {
  export TARGETARCH=386
  testHelloCPPLLD
}
