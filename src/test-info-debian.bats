#!/usr/bin/env bats

load "assert"

vendor="debian"

if grep "Ubuntu" /etc/issue 2>/dev/null >/dev/null; then
  vendor="ubuntu"
fi

@test "vendor" {
  assert_equal "$vendor" "$(xx-info vendor)"
}

@test "libc" {
  assert_equal "gnu" "$(xx-info libc)"
  assert_equal "musl" "$(XX_LIBC=musl xx-info libc)"
}

@test "debian-arch" {
  assert_equal "$(xx-info debian-arch)" "$(xx-info pkg-arch)"
}

@test "amd64" {
  assert_equal "x86_64-linux-gnu" "$(TARGETPLATFORM=linux/amd64 xx-info triple)"
  assert_equal "amd64" "$(TARGETPLATFORM=linux/amd64 xx-info pkg-arch)"
}

@test "aarch64" {
  assert_equal "aarch64-linux-gnu" "$(TARGETPLATFORM=linux/arm64 xx-info triple)"
  assert_equal "arm64" "$(TARGETPLATFORM=linux/arm64 xx-info pkg-arch)"
}

@test "arm" {
  assert_equal "arm-linux-gnueabihf" "$(TARGETPLATFORM=linux/arm xx-info triple)"
  assert_equal "armhf" "$(TARGETPLATFORM=linux/arm xx-info pkg-arch)"
  assert_equal "v7" "$(TARGETPLATFORM=linux/arm xx-info variant)"

  assert_equal "armv7-linux-gnueabihf" "$(TARGETPLATFORM=linux/arm ARM_TARGET_ARCH=armv7 xx-info triple)"
  assert_equal "armhf" "$(TARGETPLATFORM=linux/arm ARM_TARGET_ARCH=armv7 xx-info pkg-arch)" # does not change
  assert_equal "armv7-unknown-linux-gnueabihf" "$(TARGETPLATFORM=linux/arm ARM_TARGET_ARCH=armv7 XX_VENDOR=unknown xx-info triple)"
}

@test "armv6" {
  assert_equal "arm-linux-gnueabi" "$(TARGETPLATFORM=linux/arm/v6 xx-info triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v6 xx-info pkg-arch)"
  assert_equal "v6" "$(TARGETPLATFORM=linux/arm/v6 xx-info variant)"
}

@test "armv5" {
  assert_equal "arm-linux-gnueabi" "$(TARGETPLATFORM=linux/arm/v5 xx-info triple)"
  assert_equal "armel" "$(TARGETPLATFORM=linux/arm/v5 xx-info pkg-arch)"
  assert_equal "v5" "$(TARGETPLATFORM=linux/arm/v5 xx-info variant)"
}

@test "386" {
  assert_equal "i686-linux-gnu" "$(TARGETPLATFORM=linux/386 xx-info triple)"
  assert_equal "i386" "$(TARGETPLATFORM=linux/386 xx-info pkg-arch)"
}

@test "ppc64le" {
  assert_equal "powerpc64le-linux-gnu" "$(TARGETPLATFORM=linux/ppc64le xx-info triple)"
  assert_equal "ppc64el" "$(TARGETPLATFORM=linux/ppc64le xx-info pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x-linux-gnu" "$(TARGETPLATFORM=linux/s390x xx-info triple)"
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64-linux-gnu" "$(TARGETPLATFORM=linux/riscv64 xx-info triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info pkg-arch)"

  assert_equal "riscv64gc-linux-gnu" "$(TARGETPLATFORM=linux/riscv64 RISCV64_TARGET_ARCH=riscv64gc xx-info triple)"
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 RISCV64_TARGET_ARCH=riscv64gc xx-info pkg-arch)" # does not change
  assert_equal "riscv64gc-unknown-linux-gnu" "$(TARGETPLATFORM=linux/riscv64 RISCV64_TARGET_ARCH=riscv64gc XX_VENDOR=unknown xx-info triple)"
}

@test "loong64" {
  assert_equal "loongarch64-linux-gnu" "$(TARGETPLATFORM=linux/loong64 xx-info triple)"
  assert_equal "loong64" "$(TARGETPLATFORM=linux/loong64 xx-info pkg-arch)"
}

@test "mips" {
  assert_equal "mips-linux-gnu" "$(TARGETPLATFORM=linux/mips xx-info triple)"
  assert_equal "mips" "$(TARGETPLATFORM=linux/mips xx-info pkg-arch)"
}

@test "mipsle" {
  assert_equal "mipsel-linux-gnu" "$(TARGETPLATFORM=linux/mipsle xx-info triple)"
  assert_equal "mipsel" "$(TARGETPLATFORM=linux/mipsle xx-info pkg-arch)"
}

@test "mips64" {
  assert_equal "mips64-linux-gnuabi64" "$(TARGETPLATFORM=linux/mips64 xx-info triple)"
  assert_equal "mips64" "$(TARGETPLATFORM=linux/mips64 xx-info pkg-arch)"
}

@test "mips64le" {
  assert_equal "mips64el-linux-gnuabi64" "$(TARGETPLATFORM=linux/mips64le xx-info triple)"
  assert_equal "mips64el" "$(TARGETPLATFORM=linux/mips64le xx-info pkg-arch)"
}

@test "sysroot" {
  assert_equal "/" "$(xx-info sysroot)"
  assert_equal "/" "$(TARGETPLATFORM=linux/amd64 xx-info sysroot)"
  assert_equal "/" "$(TARGETPLATFORM=linux/arm64 xx-info sysroot)"
  assert_equal "/" "$(TARGETPLATFORM=linux/riscv64 xx-info sysroot)"
}
