#!/usr/bin/env bash

add() {
  if [ -f /etc/alpine-release ]; then
    apk add "$@"
  else
    xxrun apt install -y --no-install-recommends "$@"
  fi
}

del() {
  if [ -f /etc/alpine-release ]; then
    apk del "$@" 2>/dev/null || true
  else
    xxrun apt remove --autoremove -y "$@" 2>/dev/null || true
  fi
}

xxadd() {
  if [ -f /etc/alpine-release ]; then
    xx-apk add "$@"
  else
    xxrun xx-apt install -y --no-install-recommends "$@"
  fi
}

xxdel() {
  if [ -f /etc/alpine-release ]; then
    xx-apk add "$@" 2>/dev/null || true
  else
    xxrun xx-apt install -y --autoremove "$@" 2>/dev/null || true
  fi
}

xxrun() {
  wasclang=
  wasgolang=
  # need to replace clang with clang-11 on buster as clang-7 is not supported
  if grep -q "buster-backports" /etc/apt/sources.list.d/backports.list 2>/dev/null; then
    n=$#
    for p in "$@"; do
      if [ $# = $n ]; then set --; fi
      if [ "$p" = "clang" ]; then
        p="clang-11"
        wasclang=1
      fi
      if [ "$p" = "golang" ]; then
        p="golang-1.15"
        wasgolang=1
      fi
      set -- "$@" "$p"
    done
  fi
  "$@" || return $?
  if [ -n "$wasclang" ]; then
    if [ -f /usr/bin/clang-11 ] && [ ! -e /usr/bin/clang ]; then
      ln -s clang-11 /usr/bin/clang
      ln -s clang++-11 /usr/bin/clang++
    fi
    if [ ! -f /usr/bin/clang-11 ] && [ "clang11" = "$(readlink $(command -v clang))" ]; then
      rm /usr/bin/clang
      rm /usr/bin/clang++
    fi
  fi
  if [ -n "$wasgolang" ] && ! command -v go 2>/dev/null >/dev/null; then
    ln -s /usr/lib/go-1.15/bin/go /usr/bin/go
  fi
}

supportRiscV() {
  if [ -f /etc/debian_version ]; then
    if grep "sid main" /etc/apt/sources.list 2>/dev/null >/dev/null; then
      return 0
    else
      return 1
    fi
  fi
  return 0
}

supportRiscVGo() {
  go version | grep -E "1.14|1.15|1.16|1.17|1.18|1.19" >/dev/null 2>&1
}

supportRiscVCGo() {
  if ! supportRiscV; then
    return 1
  fi
  go version | egrep -E "1.16|1.17|1.18|1.19" >/dev/null 2>&1
}

supportLoongArch() {
  if [ -f /etc/debian_version ]; then
    if grep "sid" /etc/apt/sources.list 2>/dev/null >/dev/null; then
      return 0
    else
      return 1
    fi
  fi
  return 0
}

supportLoongArchGo() {
  go version | grep -E "1.14|1.15|1.16|1.17|1.18|1.19|1.20|1.21" >/dev/null 2>&1
}

supportLoongArchCGo() {
  if ! supportLoongArch; then
    return 1
  fi
  go version | egrep -E "1.16|1.17|1.18|1.19|1.20|1.21" >/dev/null 2>&1
}

supportRC() {
  command -v llvm-rc >/dev/null 2>&1
}
