#!/usr/bin/env sh

: ${TARGETPLATFORM=}

set -eu

is_target=
is_out=
is_build=

target=

if [ -n "$TARGETPLATFORM" ]; then
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then
    target="aarch64-unknown-linux-gnu"
  fi
  if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then
    target="arm-unknown-linux-gnueabihf"
  fi
  if [ "$TARGETPLATFORM" = "linux/arm" ]; then
    target="arm-unknown-linux-gnueabihf"
  fi
  if [ "$TARGETPLATFORM" = "wasi/wasm" ]; then
    target="wasm32-wasi"
  fi
fi

for opt in "$@"
do
  case "$opt" in
    build) is_build=1
    ;;
    --target*) is_target=1
    ;;
    --out-dir*) is_out=1
    ;;
  esac
done

if [ "$is_build" = "1" ]; then
  targetflag=
  if [ "$is_target" != "1" ] && [ "$target" != "" ]; then
    targetflag="--target $target"
  fi
  outflag=
  if [ "$is_out" = "1" ]; then
    outflag="-Z unstable-options"
  fi
  /root/.cargo/bin/cargo "$@" $outflag $targetflag
else
  /root/.cargo/bin/cargo "$@"
fi