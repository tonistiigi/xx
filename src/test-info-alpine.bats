#!/usr/bin/env bats

load 'assert'

@test "vendor" {
  assert_equal "alpine" "$(xx-info vendor)"
}

@test "libc" {
  assert_equal "musl" "$(xx-info libc)"
  assert_equal "gnu" "$(XX_LIBC=gnu xx-info libc)"
}

@test "libc-override" {
  assert_equal "aarch64-alpine-linux-gnu" "$(TARGETPLATFORM=linux/arm64 XX_LIBC=gnu xx-info triple)"
}

@test "alpine-arch" {
  assert_equal "$(xx-info alpine-arch)" "$(xx-info pkg-arch)"
}

@test "amd64" {
  assert_equal "x86_64-alpine-linux-musl" "$(TARGETPLATFORM=linux/amd64 xx-info triple)"
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64 xx-info pkg-arch)"
}

@test "amd64v2" {
  assert_equal "x86_64-alpine-linux-musl" "$(TARGETPLATFORM=linux/amd64/v2 xx-info triple)"
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64/v2 xx-info pkg-arch)"
  assert_equal "v2" "$(TARGETPLATFORM=linux/amd64/v2 xx-info variant)"
}

@test "amd64v3" {
  assert_equal "x86_64-alpine-linux-musl" "$(TARGETPLATFORM=linux/amd64/v3 xx-info triple)"
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64/v3 xx-info pkg-arch)"
  assert_equal "v3" "$(TARGETPLATFORM=linux/amd64/v3 xx-info variant)"
}

@test "amd64v4" {
  assert_equal "x86_64-alpine-linux-musl" "$(TARGETPLATFORM=linux/amd64/v4 xx-info triple)"
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64/v4 xx-info pkg-arch)"
  assert_equal "v4" "$(TARGETPLATFORM=linux/amd64/v4 xx-info variant)"
}

@test "aarch64" {
  assert_equal "aarch64-alpine-linux-musl" "$(TARGETPLATFORM=linux/arm64 xx-info triple)"
  assert_equal "aarch64" "$(TARGETPLATFORM=linux/arm64 xx-info pkg-arch)"
}

@test "arm" {
  assert_equal "armv7-alpine-linux-musleabihf" "$(TARGETPLATFORM=linux/arm xx-info triple)"
  assert_equal "armv7" "$(TARGETPLATFORM=linux/arm xx-info pkg-arch)"
  assert_equal "v7" "$(TARGETPLATFORM=linux/arm/v7 xx-info variant)"

  assert_equal "arm-alpine-linux-musleabihf" "$(TARGETPLATFORM=linux/arm ARM_TARGET_ARCH=arm xx-info triple)"
  assert_equal "armv7" "$(TARGETPLATFORM=linux/arm ARM_TARGET_ARCH=arm xx-info pkg-arch)" # does not change
  assert_equal "v7" "$(TARGETPLATFORM=linux/arm/v7 ARM_TARGET_ARCH=arm xx-info variant)"  # does not change
}

@test "armv6" {
  assert_equal "armv6-alpine-linux-musleabihf" "$(TARGETPLATFORM=linux/arm/v6 xx-info triple)"
  assert_equal "armhf" "$(TARGETPLATFORM=linux/arm/v6 xx-info pkg-arch)"
  assert_equal "v6" "$(TARGETPLATFORM=linux/arm/v6 xx-info variant)"
}

@test "armv5" {
  assert_equal "armv5-alpine-linux-musleabi" "$(TARGETPLATFORM=linux/arm/v5 xx-info triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v5 xx-info pkg-arch)"
  assert_equal "v5" "$(TARGETPLATFORM=linux/arm/v5 xx-info variant)"
}

@test "386" {
  assert_equal "i586-alpine-linux-musl" "$(TARGETPLATFORM=linux/386 xx-info triple)"
  assert_equal "x86" "$(TARGETPLATFORM=linux/386 xx-info pkg-arch)"
}

@test "ppc64le" {
  assert_equal "powerpc64le-alpine-linux-musl" "$(TARGETPLATFORM=linux/ppc64le xx-info triple)"
  assert_equal "ppc64le" "$(TARGETPLATFORM=linux/ppc64le xx-info pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x-alpine-linux-musl" "$(TARGETPLATFORM=linux/s390x xx-info triple)"
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64-alpine-linux-musl" "$(TARGETPLATFORM=linux/riscv64 xx-info triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info pkg-arch)"

  assert_equal "riscv64gc-alpine-linux-musl" "$(TARGETPLATFORM=linux/riscv64 RISCV64_TARGET_ARCH=riscv64gc xx-info triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 RISCV64_TARGET_ARCH=riscv64gc xx-info pkg-arch)" # does not change
}

@test "riscv64-custom-vendor" {
  assert_equal "riscv64-unknown-linux-musl" "$(TARGETPLATFORM=linux/riscv64 XX_VENDOR=unknown xx-info triple)"
}

@test "loong64" {
  assert_equal "loongarch64-alpine-linux-musl" "$(TARGETPLATFORM=linux/loong64 xx-info triple)"
  assert_equal "loongarch64" "$(TARGETPLATFORM=linux/loong64 xx-info pkg-arch)"
}

@test "mips" {
  assert_equal "mips-alpine-linux-musl" "$(TARGETPLATFORM=linux/mips xx-info triple)"
  assert_equal "mips" "$(TARGETPLATFORM=linux/mips xx-info pkg-arch)"
}

@test "mipsle" {
  assert_equal "mipsel-alpine-linux-musl" "$(TARGETPLATFORM=linux/mipsle xx-info triple)"
  assert_equal "mipsle" "$(TARGETPLATFORM=linux/mipsle xx-info pkg-arch)"
}

@test "mips64" {
  assert_equal "mips64-alpine-linux-muslabi64" "$(TARGETPLATFORM=linux/mips64 xx-info triple)"
  assert_equal "mips64" "$(TARGETPLATFORM=linux/mips64 xx-info pkg-arch)"
}

@test "mips64le" {
  assert_equal "mips64el-alpine-linux-muslabi64" "$(TARGETPLATFORM=linux/mips64le xx-info triple)"
  assert_equal "mips64le" "$(TARGETPLATFORM=linux/mips64le xx-info pkg-arch)"
}

@test "darwin" {
  assert_equal "x86_64-apple-macos10.6" "$(TARGETPLATFORM=darwin/amd64 xx-info triple)"
  assert_equal "darwin" "$(TARGETPLATFORM=darwin/amd64 xx-info os)"
  assert_equal "amd64" "$(TARGETPLATFORM=darwin/amd64 xx-info arch)"
  assert_equal "x86_64" "$(TARGETPLATFORM=darwin/amd64 xx-info march)"
  assert_equal "arm64" "$(TARGETPLATFORM=darwin/arm64 xx-info march)"
  assert_equal "arm64-apple-macos10.16" "$(TARGETPLATFORM=darwin/arm64 xx-info triple)"
  assert_equal "x86_64-apple-macos10.15" "$(TARGETPLATFORM=darwin/amd64 MACOSX_VERSION_MIN=10.15 xx-info triple)"
  assert_equal "apple" "$(TARGETPLATFORM=darwin/amd64 xx-info vendor)"
}

@test "sysroot" {
  assert_equal "/" "$(xx-info sysroot)"
  if [ "$(xx-info arch)" != "amd64" ]; then
    assert_equal "/x86_64-alpine-linux-musl/" "$(TARGETPLATFORM=linux/amd64 xx-info sysroot)"
  fi
  if [ "$(xx-info arch)" != "arm64" ]; then
    assert_equal "/aarch64-alpine-linux-musl/" "$(TARGETPLATFORM=linux/arm64 xx-info sysroot)"
  fi
  assert_equal "/xx-sdk/MacOSX11.1.sdk/" "$(TARGETPLATFORM=darwin/amd64 xx-info sysroot)"
  assert_equal "/xx-sdk/MacOSX11.1.sdk/" "$(TARGETPLATFORM=darwin/arm64 xx-info sysroot)"
}
