#!/usr/bin/env bats

load 'assert'
load 'test_helper'

clean() {
  rm /etc/llvm/xx-default.cfg || true
  rm /usr/bin/*-linux-*-clang || true
  rm /usr/bin/*-linux-*-clang++ || true
  rm /usr/bin/*-apple-*-clang || true
  rm /usr/bin/*-apple-*-clang++ || true
  rm /usr/bin/*.cfg || true
}

testHelloCLLD() {
  clean
  add clang lld
  xxadd xx-c-essentials
  run sh -c 'xx-clang --print-target-triple | sed s/unknown-//'
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
    if [ -f /etc/alpine-release ]; then
      assert_output "--target=$(xx-info triple) -fuse-ld=lld --sysroot=/$(xx-info triple)/"
    else
      assert_output "--target=$(xx-info triple) -fuse-ld=lld"
    fi
  fi
  testBuildHello
}

testHelloCPPLLD() {
  clean
  run sh -c 'xx-clang++ --print-target-triple | sed s/unknown-//'
  assert_success
  assert_output $(xx-info triple)

  xxadd xx-cxx-essentials
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
  del clang
  run xx-clang --print-target-triple
  assert_failure
  assert_output --partial "clang not found"
  [ ! -f /etc/llvm/xx-default.cfg ]
}

@test "nolinker" {
  if [ -f /etc/debian_version ]; then skip; fi # clang has dependency on ld in debian
  del lld 2>/dev/null || true
  add clang
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

  run sh -c "clang --print-target-triple | sed s/unknown-//"
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

  run sh -c "clang --print-target-triple | sed s/unknown-//"
  assert_success
  assert_output "$nativeTriple"

  run xx-clang --print-target-triple
  assert_success
  assert_output "$crossTriple"
}

@test "native-c-ld" {
  clean
  del lld
  add binutils
  run sh -c 'xx-clang --print-target-triple | sed s/unknown-//'
  assert_success
  assert_output $(xx-info triple)

  [ -f /etc/llvm/xx-default.cfg ]
  run cat /etc/llvm/xx-default.cfg
  assert_success

  assert_output "-fuse-ld=ld"
  [ -f /usr/bin/$(xx-info triple)-clang ]
  run sh -c "/usr/bin/$(xx-info triple)-clang --print-target-triple | sed s/unknown-//"
  assert_success
  assert_output $(xx-info triple)
  [ -f /usr/bin/$(xx-info triple)-clang++ ]
  [ -f /usr/bin/$(xx-info triple).cfg ]
  run cat /usr/bin/$(xx-info triple).cfg
  assert_success
  assert_output "--target=$(xx-info triple) -fuse-ld=ld"
  testBuildHello
  del binutils
}

@test "native-c++" {
  add clang
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

@test "darwin-setup" {
  clean
  export TARGETARCH=amd64
  export TARGETOS=darwin
  xx-clang --setup-target-triple
  [ -f /usr/bin/x86_64-apple-macos10.4-clang ]
  [ -f /usr/bin/x86_64-apple-macos10.4-clang++ ]

  run cat /usr/bin/x86_64-apple-macos10.4.cfg
  assert_success
  assert_output "--target=x86_64-apple-macos10.4 -fuse-ld=ld64 -isysroot /SDK/MacOSX11.1.sdk"

  export TARGETARCH=arm64
  xx-clang --setup-target-triple
  [ -f /usr/bin/arm64-apple-macos10.16-clang ]
  [ -f /usr/bin/arm64-apple-macos10.16-clang++ ]

  run cat /usr/bin/arm64-apple-macos10.16.cfg
  assert_success
  assert_output "--target=arm64-apple-macos10.16 -fuse-ld=ld64 -isysroot /SDK/MacOSX11.1.sdk"

  touch /usr/bin/ld64.signed
  chmod +x /usr/bin/ld64.signed

  clean

  xx-clang --setup-target-triple
  [ -f /usr/bin/arm64-apple-macos10.16-clang ]
  [ -f /usr/bin/arm64-apple-macos10.16-clang++ ]

  run cat /usr/bin/arm64-apple-macos10.16.cfg
  assert_success
  assert_output "--target=arm64-apple-macos10.16 -fuse-ld=/usr/bin/ld64.signed -isysroot /SDK/MacOSX11.1.sdk"

  rm /usr/bin/ld64.signed

  unset TARGETOS
  unset TARGETARCH
}

@test "windows-setup" {
  clean
  export TARGETARCH=amd64
  export TARGETOS=windows
  xx-clang --setup-target-triple
  [ -f /usr/bin/x86_64-w64-mingw32-clang ]
  [ -f /usr/bin/x86_64-w64-mingw32-clang++ ]

  run cat /usr/bin/x86_64-w64-mingw32.cfg
  assert_success
  assert_output "--target=x86_64-w64-mingw32 -fuse-ld=lld -I/usr/x86_64-w64-mingw32/include -L/usr/x86_64-w64-mingw32/lib"

  add llvm

  export TARGETARCH=arm64
  xx-clang --setup-target-triple
  [ -f /usr/bin/aarch64-w64-mingw32-clang ]
  [ -f /usr/bin/aarch64-w64-mingw32-clang++ ]

  [ -f /usr/bin/aarch64-w64-mingw32-dlltool ]
  run readlink /usr/bin/aarch64-w64-mingw32-dlltool
  assert_success
  assert_output "llvm-dlltool"

  run cat /usr/bin/aarch64-w64-mingw32.cfg
  assert_success
  assert_output "--target=aarch64-w64-mingw32 -fuse-ld=lld -I/usr/aarch64-w64-mingw32/include -L/usr/aarch64-w64-mingw32/lib"
}

@test "clean-packages" {
  for p in linux/amd64 linux/arm64 linux/ppc64le linux/s390x linux/386 linux/arm/v7 linux/arm/v6; do
    TARGETPLATFORM=$p xxdel xx-c-essentials
    TARGETPLATFORM=$p xxdel xx-cxx-essentials
    root=/$(TARGETPLATFORM=$p xx-info triple)
    if [ -d "$root" ] && [ "$root" != "/" ]; then
      rm -rf "$root"
    fi
  done
  del clang lld llvm
  rm /tmp/a.out
  rm -rf /var/cache/apt/*.bin || true
}
