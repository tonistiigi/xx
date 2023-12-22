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
  run sh -c 'xx-clang --print-target-triple | sed s/unknown-// | sed s/pc-//'
  assert_success
  assert_output $(xx-info triple)

  [ -f /usr/bin/$(xx-info triple)-clang ]
  [ -f /usr/bin/$(xx-info triple)-clang++ ]
  [ -f /usr/bin/$(xx-info triple).cfg ]
  run cat /usr/bin/$(xx-info triple).cfg
  assert_success
  if ! xx-info is-cross; then
    assert_output "--target=$(xx-info triple) -fuse-ld=lld"
    [ -f /etc/llvm/xx-default.cfg ]
    run cat /etc/llvm/xx-default.cfg
    assert_success
    assert_output "-fuse-ld=lld"
  else
    if [ -z "$expectedLinker"]; then expectedLinker="lld"; fi
    if [ -f /etc/alpine-release ]; then
      assert_output "--target=$(xx-info triple) -fuse-ld=$expectedLinker --sysroot=/$(xx-info triple)/$expectedSuffix"
    else
      assert_output "--target=$(xx-info triple) -fuse-ld=$expectedLinker$expectedSuffix"
    fi
  fi
  testBuildHello
}

testHelloCPPLLD() {
  clean
  run sh -c 'xx-clang++ --print-target-triple | sed s/unknown-// | sed s/pc-//'
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
  export XX_NO_DOWNLOAD=1
  if [ -f /etc/debian_version ]; then skip; fi # clang has dependency on ld in debian
  if [ -f /etc/alpine-release ]; then
    # clang (since 16) has a dependency on linker tools since alpine 3.18
    # https://github.com/alpinelinux/aports/blob/19182e91254966beefa20f8f110fd522c9f3454c/main/clang16/APKBUILD#L128
    alpineRelease=$(cat /etc/alpine-release)
    if grep PRETTY_NAME /etc/os-release | cut -d '=' -f 2 | tr -d '"' | grep -q "edge$" || [ "$(semver compare "$alpineRelease" "3.17.9999")" -ge 0 ]; then
      skip
    fi
  fi
  del lld 2>/dev/null || true
  add clang
  run xx-clang --print-target-triple
  assert_failure
  assert_output --partial "no suitable linker"
  [ ! -f /etc/llvm/xx-default.cfg ]
  unset XX_NO_DOWNLOAD
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

  run sh -c "clang --print-target-triple | sed s/unknown-// | sed s/pc-//"
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

  run sh -c "clang --print-target-triple | sed s/unknown-// | sed s/pc-//"
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
  export XX_NO_DOWNLOAD=1
  run sh -c 'xx-clang --print-target-triple | sed s/unknown-// | sed s/pc-//'
  assert_success
  assert_output $(xx-info triple)

  [ -f /etc/llvm/xx-default.cfg ]
  run cat /etc/llvm/xx-default.cfg
  assert_success

  assert_output "-fuse-ld=/usr/bin/$(xx-info triple)-ld"
  [ -f /usr/bin/$(xx-info triple)-clang ]
  run sh -c "/usr/bin/$(xx-info triple)-clang --print-target-triple | sed s/unknown-// | sed s/pc-//"
  assert_success
  assert_output $(xx-info triple)
  [ -f /usr/bin/$(xx-info triple)-clang++ ]
  [ -f /usr/bin/$(xx-info triple).cfg ]
  run cat /usr/bin/$(xx-info triple).cfg
  assert_success
  assert_output "--target=$(xx-info triple) -fuse-ld=/usr/bin/$(xx-info triple)-ld"
  testBuildHello
  del binutils
}

@test "prefer-static-linker" {
  clean
  add clang lld
  export XX_NO_DOWNLOAD=1
  export XX_CC_PREFER_STATIC_LINKER=1

  export TARGETPLATFORM="linux/ppc64le"

  touch /usr/bin/$(xx-info triple)-ld
  chmod +x /usr/bin/$(xx-info triple)-ld

  run xx-clang --setup-target-triple
  assert_success

  run cat /usr/bin/$(xx-info).cfg
  assert_success
  assert_output --partial "-fuse-ld=/usr/bin/powerpc64le-"
  assert_output --partial "-ld"

  clean
  add clang lld
  unset XX_CC_PREFER_STATIC_LINKER

  run xx-clang --setup-target-triple
  assert_success

  run cat /usr/bin/$(xx-info).cfg
  assert_success
  assert_output --partial "-fuse-ld=lld"

  unset TARGETPLATFORM
  rm /usr/bin/$(xx-info triple)-ld
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
  if [ "$(xx-info vendor)" = "ubuntu" ]; then skip; fi
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

@test "riscv64-c-ld" {
  if ! supportRiscV; then
    skip "RISC-V not supported"
  fi
  export TARGETARCH=riscv64
  expectedLinker="/usr/bin/riscv64-alpine-linux-musl-ld"
  if [ ! -f "/etc/alpine-release" ]; then
    expectedLinker="/usr/bin/riscv64-linux-gnu-ld"
  else
    expectedSuffix=" -Wl,-rpath-link,/riscv64-alpine-linux-musl/usr/lib"
  fi
  testHelloCLLD # actually runs with ld
  expectedLinker=
  expectedSuffix=
}

@test "loong64-c-ld" {
  skip "LOONG64 not supported"
  export TARGETARCH=loong64
  testHelloCLLD # actually runs with ld
  expectedLinker=
  expectedSuffix=
}

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
  if [ "$(xx-info vendor)" = "ubuntu" ]; then skip; fi
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

@test "riscv64-c++-ld" {
  if ! supportRiscV; then
    skip "RISC-V not supported"
  fi
  export TARGETARCH=riscv64
  testHelloCPPLLD # actually runs with ld
}

@test "loong64-c++-ld" {
  skip "LOONG64 not supported"
  export TARGETARCH=loong64
  testHelloCPPLLD # actually runs with ld
}

@test "386-c++-lld" {
  export TARGETARCH=386
  testHelloCPPLLD
}

@test "darwin-setup" {
  clean
  export TARGETARCH=amd64
  export TARGETOS=darwin
  export XX_NO_DOWNLOAD=1
  xx-clang --setup-target-triple
  [ -f /usr/bin/x86_64-apple-macos10.6-clang ]
  [ -f /usr/bin/x86_64-apple-macos10.6-clang++ ]

  run cat /usr/bin/x86_64-apple-macos10.6.cfg
  assert_success
  assert_output "--target=x86_64-apple-macos10.6 -fuse-ld=ld64 -isysroot /xx-sdk/MacOSX11.1.sdk -stdlib=libc++"

  export TARGETARCH=arm64
  xx-clang --setup-target-triple
  [ -f /usr/bin/arm64-apple-macos10.16-clang ]
  [ -f /usr/bin/arm64-apple-macos10.16-clang++ ]

  run cat /usr/bin/arm64-apple-macos10.16.cfg
  assert_success
  assert_output "--target=arm64-apple-macos10.16 -fuse-ld=ld64 -isysroot /xx-sdk/MacOSX11.1.sdk -stdlib=libc++"

  touch /usr/bin/ld64.signed
  chmod +x /usr/bin/ld64.signed

  clean

  xx-clang --setup-target-triple
  [ -f /usr/bin/arm64-apple-macos10.16-clang ]
  [ -f /usr/bin/arm64-apple-macos10.16-clang++ ]

  run cat /usr/bin/arm64-apple-macos10.16.cfg
  assert_success
  assert_output "--target=arm64-apple-macos10.16 -fuse-ld=/usr/bin/ld64.signed -isysroot /xx-sdk/MacOSX11.1.sdk -stdlib=libc++"

  clean

  mkdir -p /xx-sdk/MacOSX11.2.sdk
  xx-clang --setup-target-triple
  [ -f /usr/bin/arm64-apple-macos10.16-clang ]
  [ -f /usr/bin/arm64-apple-macos10.16-clang++ ]

  run cat /usr/bin/arm64-apple-macos10.16.cfg
  assert_success
  assert_output "--target=arm64-apple-macos10.16 -fuse-ld=/usr/bin/ld64.signed -isysroot /xx-sdk/MacOSX11.2.sdk -stdlib=libc++"

  rm -r /xx-sdk/MacOSX11.2.sdk
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
