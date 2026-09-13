#!/usr/bin/env bats

load 'assert'
load 'test_helper'

setup_file() {
  if [ -f /etc/alpine-release ]; then
    add zig
  else
    add ca-certificates wget xz-utils
    case "$(uname -m)" in
      x86_64) checksum=70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00 ;;
      aarch64) checksum=ea4b09bfb22ec6f6c6ceac57ab63efb6b46e17ab08d21f69f3a48b38e1534f17 ;;
      *)
        echo >&2 'Zig tests require an amd64 or arm64 build platform'
        return 1
        ;;
    esac
    wget -O /tmp/zig.tar.xz "https://ziglang.org/download/0.16.0/zig-$(uname -m)-linux-0.16.0.tar.xz"
    echo "$checksum  /tmp/zig.tar.xz" | sha256sum -c -
    mkdir -p /opt/zig
    tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1
    ln -s /opt/zig/zig /usr/bin/zig
  fi
  zig version
  xx-verify --setup
}

setup() {
  unset TARGETPLATFORM TARGETPAIR TARGETARCH TARGETVARIANT XX_LIBC
  export TARGETOS=linux
}

@test "target triples" {
  while read -r platform expected; do
    for libc in musl gnu; do
      run env TARGETPLATFORM="$platform" XX_VENDOR=debian XX_LIBC="$libc" xx-zig --print-target-triple
      assert_success
      assert_output "${expected/LIBC/$libc}"
    done
  done <<EOF
linux/amd64 x86_64-linux-LIBC
linux/arm64 aarch64-linux-LIBC
linux/386 x86-linux-LIBC
linux/arm/v5 arm-linux-LIBCeabi
linux/arm/v6 arm-linux-LIBCeabi
linux/arm/v7 arm-linux-LIBCeabihf
linux/ppc64le powerpc64le-linux-LIBC
linux/riscv64 riscv64-linux-LIBC
linux/s390x s390x-linux-LIBC
linux/loong64 loongarch64-linux-LIBC
darwin/amd64 x86_64-macos-none
darwin/arm64 aarch64-macos-none
windows/amd64 x86_64-windows-gnu
windows/386 x86-windows-gnu
windows/arm64 aarch64-windows-gnu
windows/arm/v7 arm-windows-gnu
EOF
}

@test "Alpine ARMv6 uses the package ABI" {
  run env TARGETPLATFORM=linux/arm/v6 XX_VENDOR=alpine XX_LIBC=musl xx-zig --print-target-triple
  assert_success
  assert_output 'arm-linux-musleabihf'
}

@test "MIPS target ABIs" {
  while read -r arch libc expected; do
    run env TARGETARCH="$arch" XX_LIBC="$libc" xx-zig --print-target-triple
    assert_success
    assert_output "$expected"
  done <<EOF
mips musl mips-linux-musl
mips gnu mips-linux-gnueabi
mipsle musl mipsel-linux-musl
mipsle gnu mipsel-linux-gnueabi
mips64 musl mips64-linux-musl
mips64 gnu mips64-linux-gnuabi64
mips64le musl mips64el-linux-musl
mips64le gnu mips64el-linux-gnuabi64
EOF
}

@test "compiler arguments and exit status" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/zig" <<'EOF'
#!/bin/sh
printf '<%s>\n' "$@"
exit 42
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/zig"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" TARGETARCH=arm64 XX_LIBC=musl xx-zig c++ -D'MESSAGE="hello world"' -o 'hello world'
  assert_failure 42
  assert_output $'<c++>\n<-target>\n<aarch64-linux-musl>\n<-DMESSAGE="hello world">\n<-o>\n<hello world>'
}

@test "unsupported command" {
  run xx-zig build
  assert_failure
  assert_output --partial 'unsupported command: build'
}

@test "missing compiler" {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  ln -s "$(command -v sh)" "$BATS_TEST_TMPDIR/bin/sh"
  cat >"$BATS_TEST_TMPDIR/bin/xx-info" <<'EOF'
#!/bin/sh
echo 'TARGETOS=linux TARGETARCH=amd64 XX_LIBC=musl'
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/xx-info"
  run env PATH="$BATS_TEST_TMPDIR/bin" "$(command -v xx-zig)" --print-target-triple
  assert_success
  assert_output 'x86_64-linux-musl'
  run env PATH="$BATS_TEST_TMPDIR/bin" "$(command -v xx-zig)" cc fixtures/hello.c
  assert_failure
  assert_output --partial 'zig not found'
}

testHelloZig() {
  for compiler in cc c++; do
    source=fixtures/hello.c
    expected='hello c'
    if [ "$compiler" = c++ ]; then
      source=fixtures/hello.cc
      expected='hello c++'
    fi
    run xx-zig "$compiler" "$@" -o "$BATS_TEST_TMPDIR/hello" "$source"
    assert_success
    run xx-verify "$BATS_TEST_TMPDIR/hello"
    assert_success
    if ! xx-info is-cross && { [ "$XX_VERIFY_STATIC" = 1 ] || [ "$(xx-info libc)" = "$(XX_LIBC= xx-info libc)" ]; }; then
      run "$BATS_TEST_TMPDIR/hello"
      assert_success
      assert_output "$expected"
    fi
  done
}

@test "native C and C++" { testHelloZig; }
@test "amd64 C and C++" {
  export TARGETARCH=amd64
  testHelloZig
}
@test "386 C and C++" {
  export TARGETARCH=386
  testHelloZig
}
@test "arm64 C and C++" {
  export TARGETARCH=arm64
  testHelloZig
}
@test "armv6 C and C++" {
  export TARGETARCH=arm TARGETVARIANT=v6
  testHelloZig
}
@test "armv7 C and C++" {
  export TARGETARCH=arm TARGETVARIANT=v7
  testHelloZig
}
@test "ppc64le C and C++" {
  export TARGETARCH=ppc64le
  testHelloZig
}
@test "riscv64 C and C++" {
  export TARGETARCH=riscv64
  testHelloZig
}
@test "loong64 C and C++" {
  export TARGETARCH=loong64
  if ! zig targets | grep -q "\"$(xx-zig --print-target-triple)\""; then
    skip "Zig $(zig version) does not provide libc for $(xx-zig --print-target-triple)"
  fi
  testHelloZig
}

@test "static C and C++" {
  # Zig's bundled glibc only supports dynamic linking.
  export XX_LIBC=musl
  export XX_VERIFY_STATIC=1
  testHelloZig -static
  export TARGETARCH=arm64
  testHelloZig -static
}

@test "dynamic C and C++" {
  export XX_LIBC=gnu
  testHelloZig -dynamic
  run file "$BATS_TEST_TMPDIR/hello"
  assert_success
  assert_output --partial 'dynamically linked'
}

@test "shared C and C++ libraries" {
  export TARGETARCH=arm64
  testHelloZig -shared -fPIC
}

@test "explicit target overrides the environment" {
  export TARGETARCH=arm TARGETVARIANT=v6
  run xx-zig cc -target x86_64-linux-musl -o "$BATS_TEST_TMPDIR/hello" fixtures/hello.c
  assert_success
  run env TARGETARCH=amd64 xx-verify "$BATS_TEST_TMPDIR/hello"
  assert_success
}

@test "ARM CPU variants" {
  export TARGETARCH=arm
  for variant in 5 6; do
    run env TARGETVARIANT="v$variant" xx-zig cc -dM -E -x c /dev/null
    assert_success
    assert_output --partial "#define __ARM_ARCH $variant"
  done
  run env TARGETVARIANT=v6 xx-zig cc -mcpu=cortex_a7 -dM -E -x c /dev/null
  assert_success
  assert_output --partial '#define __ARM_ARCH 7'
}

@test "unsupported target OS" {
  run env TARGETOS=freebsd xx-zig --print-target-triple
  assert_failure
  assert_output --partial 'unsupported target OS: freebsd'
}

@test "target library from the package manager" {
  export TARGETARCH=arm64
  if [ "$(uname -m)" = aarch64 ]; then
    export TARGETARCH=amd64
  fi
  triple=$(xx-info triple)
  if [ -f /etc/alpine-release ]; then
    add pkgconf
    xxadd zlib-dev
    export PKG_CONFIG_SYSROOT_DIR="/$triple"
    export PKG_CONFIG_LIBDIR="/$triple/usr/lib/pkgconfig"
  else
    add pkg-config
    xxadd zlib1g-dev
    export PKG_CONFIG_LIBDIR="/usr/lib/$triple/pkgconfig"
    export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1
  fi
  cat >"$BATS_TEST_TMPDIR/zlib.c" <<'EOF'
#include <zlib.h>
int main(void) { return zlibVersion()[0] == '\0'; }
EOF
  for compiler in cc c++; do
    # pkg-config output is a list of compiler arguments.
    run xx-zig "$compiler" -o "$BATS_TEST_TMPDIR/zlib" "$BATS_TEST_TMPDIR/zlib.c" $(pkg-config --cflags --libs zlib)
    assert_success
    run xx-verify "$BATS_TEST_TMPDIR/zlib"
    assert_success
  done
}
