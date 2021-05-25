#!/usr/bin/env sh

: ${TARGETPLATFORM=}

set -eu

if [ -n "$TARGETPLATFORM" ]; then
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then
    exec aarch64-unknown-linux-clang "$@"
  fi
  if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then
    exec arm-linux-gnueabihf-clang "$@"
  fi
  if [ "$TARGETPLATFORM" = "linux/arm" ]; then
    exec arm-linux-gnueabihf-clang "$@"
  fi
  if [ "$TARGETPLATFORM" = "wasi/wasm" ]; then
    exec wasm32-wasi-clang "$@"
  fi
fi

/usr/bin/clang "$@"
