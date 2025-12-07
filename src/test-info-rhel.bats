#!/usr/bin/env bats

load "assert"

vendor="rhel"
if grep </etc/redhat-release "Fedora" 2>/dev/null >/dev/null; then
  vendor="fedora"
elif grep </etc/redhat-release "CentOS" 2>/dev/null >/dev/null; then
  vendor="centos"
elif grep </etc/redhat-release "Rocky Linux" 2>/dev/null >/dev/null; then
  vendor="rocky"
elif [ -f /etc/oracle-release ] && grep </etc/oracle-release "Oracle Linux" 2>/dev/null >/dev/null; then
  vendor="ol"
fi

@test "vendor" {
  assert_equal "$vendor" "$(xx-info vendor)"
}

@test "rhel-arch" {
  assert_equal "$(xx-info rhel-arch)" "$(xx-info pkg-arch)"
}

@test "amd64" {
  assert_equal "x86_64" "$(TARGETPLATFORM=linux/amd64 xx-info pkg-arch)"
}

@test "aarch64" {
  assert_equal "aarch64" "$(TARGETPLATFORM=linux/arm64 xx-info pkg-arch)"
}

@test "arm" {
  assert_equal "armv7hl" "$(TARGETPLATFORM=linux/arm xx-info pkg-arch)"
  assert_equal "v7" "$(TARGETPLATFORM=linux/arm xx-info variant)"
}

@test "armv6" {
  assert_equal "armv6hl" "$(TARGETPLATFORM=linux/arm/v6 xx-info pkg-arch)"
  assert_equal "v6" "$(TARGETPLATFORM=linux/arm/v6 xx-info variant)"
}

@test "armv5" {
  assert_equal "armv5tel" "$(TARGETPLATFORM=linux/arm/v5 xx-info pkg-arch)"
  assert_equal "v5" "$(TARGETPLATFORM=linux/arm/v5 xx-info variant)"
}

@test "386" {
  assert_equal "i386" "$(TARGETPLATFORM=linux/386 xx-info pkg-arch)"
}

@test "ppc64le" {
  assert_equal "ppc64le" "$(TARGETPLATFORM=linux/ppc64le xx-info pkg-arch)"
}

@test "s390x" {
  assert_equal "s390x" "$(TARGETPLATFORM=linux/s390x xx-info pkg-arch)"
}

@test "riscv64" {
  assert_equal "riscv64" "$(TARGETPLATFORM=linux/riscv64 xx-info pkg-arch)"
}

@test "loong64" {
  assert_equal "loongarch64" "$(TARGETPLATFORM=linux/loong64 xx-info pkg-arch)"
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
