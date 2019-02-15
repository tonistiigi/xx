#!/usr/bin/env sh

: ${TARGETPLATFORM=}

set -eu
target="$(uname -m)-linux-gnu"

if [ -n "$TARGETPLATFORM" ]; then
  arch="$(echo $TARGETPLATFORM | cut -d"/" -f2)"
  case "$arch" in
  "amd64")
    target="x86_64-linux-gnu"
    ;;
  "arm")
    case "$(echo $TARGETPLATFORM | cut -d"/" -f3)" in
    "v5")
      target="arm-linux-gnueabi"
      ;;
    "v6")
      target="arm-linux-gnueabi"
      ;;
		"v8")
      target="aarch64-linux-gnu"
      ;;
    *)
      target="arm-linux-gnueabihf"
      ;;
    esac
    ;;
  "arm64")
    target="aarch64-linux-gnu"
    ;;
  "s390x")
    target="s390x-linux-gnu"
    ;;
  "ppc64le")
    target="powerpc64le-linux-gnu"
    ;;
  esac
fi

bin="$(echo $0 | cut -d"-" -f4)"

if [ "$bin" = "gcc" ] || [ "$bin" = "g++" ] || [ "$bin" = "ld" ]; then
	exec "$target-$bin" "$@"
else
	echo $target
fi
