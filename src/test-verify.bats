#!/usr/bin/env bats

load 'assert'

@test "native" {
  run xx-verify /bin/ls
  assert_success
}

@test "flags" {
  run xx-verify
  assert_failure
  assert_output --partial "Usage"

  run xx-verify --setup
  assert_success

  run xx-verify --static
  assert_failure
  assert_output --partial "Usage"

  run xx-verify --static2
  assert_failure
  assert_output --partial "invalid flag"

  run xx-verify --static /bin/ls
  assert_failure
  assert_output --partial "not statically linked"
}

@test "static" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped"
  export TARGETPLATFORM=linux/arm64
  run xx-verify --static /idontexist
  assert_failure
  assert_output --partial "not statically linked"

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, with debug_info, not stripped"
  export TARGETPLATFORM=linux/amd64
  run xx-verify --static /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), static-pie linked, with debug_info, not stripped"
  run xx-verify --static /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, with debug_info, not stripped"
  export TARGETPLATFORM=linux/arm64
  run xx-verify --static /idontexist
  assert_success

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}

@test "static-env" {
  export XX_VERIFY_STATIC=1

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped"
  export TARGETPLATFORM=linux/arm64
  run xx-verify /idontexist
  assert_failure
  assert_output --partial "not statically linked"

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, with debug_info, not stripped"
  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_success

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset XX_VERIFY_STATIC
  unset TARGETPLATFORM
}

@test "darwin" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": Mach-O 64-bit executable x86_64"
  export TARGETPLATFORM=darwin/amd64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=darwin/arm64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=windows/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": Mach-O 64-bit executable arm64"
  export TARGETPLATFORM=darwin/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=darwin/arm64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=darwin/arm
  run xx-verify /idontexist
  assert_failure

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}

@test "windows" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": PE32+ executable (console) x86-64 (stripped to external PDB), for MS Windows"
  export TARGETPLATFORM=windows/amd64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=windows/arm64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=darwin/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": PE32+ executable (console) ARM64 (stripped to external PDB), for MS Windows"
  export TARGETPLATFORM=windows/arm64
  run xx-verify /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": PE32+ executable (console) Aarch64 (stripped to external PDB), for MS Windows"
  export TARGETPLATFORM=windows/arm64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=windows/arm
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=windows/arm
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": PE32 executable (console) ARMv7 Thumb (stripped to external PDB), for MS Windows"
  export TARGETPLATFORM=windows/arm
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=windows/arm64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/arm
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": PE32 executable (console) Intel i386 (stripped to external PDB), for MS Windows"
  export TARGETPLATFORM=windows/386
  run xx-verify /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": PE32 executable (console) Intel 80386 (stripped to external PDB), for MS Windows"
  export TARGETPLATFORM=windows/386
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=windows/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/386
  run xx-verify /idontexist
  assert_failure

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}

@test "linux" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, stripped"
  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/arm64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=darwin/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=windows/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=freebsd/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, stripped"
  export TARGETPLATFORM=linux/arm64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/arm
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, Go BuildID=9SFsUdDWBnHFg66bZmbU/swMmjBFa_SysaP8A8W_u/X4c8ljiSZkLzFJZnxQ69/BRIIL6S2KBBMnmo4nsZZ, not stripped"
  export TARGETPLATFORM=linux/arm
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/arm/v6
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/arm64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 32-bit LSB executable, Intel i386, version 1 (SYSV), statically linked, Go BuildID=GUb5psm2_Qmc_LlEF7GP/wcIHIg_4MjQh8NC5wfep/LSmTmWKKZ5smuAQbfeFE/FBYRjFmbJQpV--JKtz4i, not stripped"
  export TARGETPLATFORM=linux/386
  run xx-verify /idontexist
  assert_success

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, Go BuildID=GUb5psm2_Qmc_LlEF7GP/wcIHIg_4MjQh8NC5wfep/LSmTmWKKZ5smuAQbfeFE/FBYRjFmbJQpV--JKtz4i, not stripped"
  export TARGETPLATFORM=linux/386
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, UCB RISC-V, version 1 (SYSV), statically linked, Go BuildID=UQcwUow8zf8eT1LVTlSd/oF4-1H5Bw_QMKx9FnmaO/CQKB2Ez22hbE9YYvWKd7/Ur6aiNESa-AIP6Ro1rJl, not stripped"
  export TARGETPLATFORM=linux/riscv64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit MSB executable, IBM S/390, version 1 (SYSV), statically linked, Go BuildID=qwRVuYDyb9tpvSA7lQYY/qVoTrD4RSf27VhrBT3PC/JoZWbzgRDaFm7oTKdd6z/yZwLvl0-pkyydk5jlTy-, not stripped"
  export TARGETPLATFORM=linux/s390x
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, LoongArch, version 1 (SYSV), statically linked, BuildID[sha1]=4d126b33c220ba2efd23ed68a46ef0db96c31f76, not stripped"
  export TARGETPLATFORM=linux/loong64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}

@test "powerpc" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500, version 1 (SYSV), statically linked, Go BuildID=G9tFhO-5w5V1jGY1nq03/ZBZGDzsQwa9qsqYoGAHs/iVDG5nvtXloF0ZsBbrVc/xceZ8JFoRhBEBWj-bHWq, not stripped"
  export TARGETPLATFORM=linux/ppc64le
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/ppc64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=freebsd/ppc64le
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit MSB executable, 64-bit PowerPC or cisco 7500, version 1 (SYSV), statically linked, Go BuildID=NTJCtXHD7Nu0ME2rlJPD/9fIhp9NVHkc4NCQefR-5/WLWGdt9Rg5U7LQ-S5oRq/3Ntbm4FkyjDaDAcnCrR0, not stripped"
  export TARGETPLATFORM=linux/ppc64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/ppc64le
  run xx-verify /idontexist
  assert_failure

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}

@test "mips" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit MSB executable, MIPS, MIPS-III version 1 (SYSV), statically linked, Go BuildID=77Ws5TiC_9ZYe25BIAM4/a1_qVyPawMwkNHvvV4ll/SIu3yPYvbmNdJGGtpi28/lAelXiZun7P04qEv_cbD, not stripped"
  export TARGETPLATFORM=linux/mips64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/mips
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=freebsd/mips64le
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, MIPS, MIPS-III version 1 (SYSV), statically linked, Go BuildID=W27AyLn63oLqRLBKCEUh/BmXyAlBlNNBVj1GSGPWV/dCa4j32KRGxwTzCf2DYV/cgmNcrUYqSXyjQZ_AsjA, not stripped"
  export TARGETPLATFORM=linux/mips64le
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=linux/mips64
  run xx-verify /idontexist
  assert_failure

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}

@test "bsd" {
  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, x86-64, version 1 (FreeBSD), statically linked, Go BuildID=JzHsKKvTrpHA0kte6HY_/RDYVwSF6JCS9Yi-Nonvh/IVJmyepFXpNmoQZjTkjJ/bRVzwhsiIAOGiEWLblTC, not stripped"
  export TARGETPLATFORM=freebsd/amd64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=freebsd/arm64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=darwin/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=netbsd/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, ARM aarch64, version 1 (FreeBSD), statically linked, Go BuildID=uHHgkDH8Of6DIoAgIgww/iFrsc3ZJfITXmb5sCrU1/RmnlnenMLKWBig-zBWc0/SJ8iqVFe1pByQojEwcI6, not stripped"
  export TARGETPLATFORM=freebsd/arm64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=freebsd/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, x86-64, version 1 (NetBSD), statically linked, for NetBSD 7.0, Go BuildID=r2whhMpyaCx0vBCzBIWB/PE1mEok8YniJDTokl5Yq/4x-cFXAeCQ6aBV6mHXhX/Q4W3dIg4a4DMNjZHVI6s, not stripped"
  export TARGETPLATFORM=netbsd/amd64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=freebsd/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  export XX_VERIFY_FILE_CMD_OUTPUT=": ELF 64-bit LSB executable, x86-64, version 1 (OpenBSD), dynamically linked, interpreter /usr/libexec/ld.so, for OpenBSD, Go BuildID=HASlNvmUYcQqznD4KLzz/uWF-6ILTbaXA4vblOUhS/IvTWk7r-87qX34iKFOHl/_ZDoXMhCmv9gMSy-etK-, not stripped"
  export TARGETPLATFORM=openbsd/amd64
  run xx-verify /idontexist
  assert_success

  export TARGETPLATFORM=netbsd/amd64
  run xx-verify /idontexist
  assert_failure

  export TARGETPLATFORM=linux/amd64
  run xx-verify /idontexist
  assert_failure

  unset XX_VERIFY_FILE_CMD_OUTPUT
  unset TARGETPLATFORM
}
