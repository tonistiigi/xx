#!/usr/bin/env bats

load 'assert'
load 'test_helper'

@test "invalid" {
  add llvm

  run xx-windres -foo foobar
  assert_failure
  assert_output "invalid option -foo"
}

@test "basic" {
  export XX_WINDRES_DRYRUN=1
  export TARGETPLATFORM=windows/arm
  export XX_TMP_FILE_FIXED=/tmp/foo
  export CC=clang
  run xx-windres -i myinp.rc -o myout.syso --use-temp-file -I /foo -D FOO=bar -UNOT -DABC=def
  assert_success
  assert_output <<EOT
clang -E -xc -D RC_INVOKED=1 -I/foo -D FOO=bar -U NOT -D ABC=def -o /tmp/foo myinp.rc
llvm-rc -fo /tmp/foo_ -I . /tmp/foo
llvm-cvtres -machine:ARM -out:myout.syso /tmp/foo_
EOT

  # custom preprocessor, output format
  export TARGETPLATFORM=windows/arm64
  run xx-windres --preprocessor=cpp -O coff -D FOO=bar -UNOT -DABC=def myinp myout
  assert_success
  assert_output <<EOT
cpp -E -xc -D RC_INVOKED=1 -D FOO=bar -U NOT -D ABC=def -o /tmp/foo myinp
llvm-rc -fo /tmp/foo_ -I . /tmp/foo
llvm-cvtres -machine:ARM64 -out:myout /tmp/foo_
EOT

  # output res
  run xx-windres -D FOO=bar myinp.rc myout.res
  assert_success
  assert_output <<EOT
clang -E -xc -D RC_INVOKED=1 -D FOO=bar -o /tmp/foo myinp.rc
llvm-rc -fo /tmp/foo_ -I . /tmp/foo
cp /tmp/foo_ myout.res
EOT

  # custom target
  run xx-windres -D FOO=bar -F pe-x86-64 mydir/myinp.rc myout.syso
  assert_success
  assert_output <<EOT
clang -E -xc -D RC_INVOKED=1 -D FOO=bar -o /tmp/foo mydir/myinp.rc
llvm-rc -fo /tmp/foo_ -I mydir /tmp/foo
llvm-cvtres -machine:X64 -out:myout.syso /tmp/foo_
EOT

}

@test "clean" {
  del llvm
}
