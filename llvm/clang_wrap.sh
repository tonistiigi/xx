#!/usr/bin/env sh

: ${TARGETPLATFORM=}

set -eu

if [ -n "$TARGETPLATFORM" ]; then
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then
    exec /usr/local/bin/clang --target=aarch64-linux-gnu "$@"
  fi
  if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then
    exec /usr/local/bin/clang --target=arm-linux-gnueabihf "$@"
  fi
  if [ "$TARGETPLATFORM" = "linux/arm" ]; then
    exec /usr/local/bin/clang --target=arm-linux-gnueabihf "$@"
  fi
  if [ "$TARGETPLATFORM" = "wasi/wasm" ]; then
    exec /usr/local/bin/clang --target=wasm32-unknown-wasi --sysroot=/src/wasi-sysroot/sysroot  "$@"
  fi
fi

/usr/local/bin/clang "$@"