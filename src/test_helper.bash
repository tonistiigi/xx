#!/usr/bin/env bash

pkg() {
  case "${op}" in
    add | install)
      alpine_op="add"
      op="install"
      apt_opts="--no-install-recommends"
      ;;
    del | remove)
      alpine_op="del"
      op="remove"
      apt_opts="--autoremove"
      ;;
    *)
      printf "Unknown op"
      exit 1
      ;;
  esac

  case "${xx}" in
    true) xx="xx-" ;;
    *) xx="" ;;
  esac

  . /etc/os-release
  # Little magic using asterisk matching with 'case'
  # ID_LIKE exists on OSes that derive from other, e.g.:
  # - Debian: ID_LIKE=""        ID="debian"
  # - Ubuntu: ID_LIKE="debian"  ID="ubuntu"
  # - Fedora: ID_LIKE=""        ID="fedora"
  # - Redhat: ID_LIKE="fedora"  ID="rhel"
  case "${ID_LIKE}${ID}" in
    alpine | chimera | adelie)
      if [ "${op}" = "install" ]; then
        ${xx}apk ${alpine_op} "$@"
      else
        ${xx}apk ${alpine_op} "$@" 2>/dev/null || true
      fi
      ;;
    debian*)
      if [ "${op}" = "install" ]; then
        xxrun ${xx}apt ${op} -y ${apt_opts} "$@"
      else
        xxrun ${xx}apt ${op} -y ${apt_opts} "$@" 2>/dev/null || true
      fi
      ;;
    fedora*)
      if [ "${op}" = "install" ]; then
        xxrun ${xx}dnf ${op} -y "$@"
      else
        xxrun ${xx}dnf ${op} -y "$@" 2>/dev/null || true
      fi
      ;;
    *)
      printf "Unknown OS:\n\t%s\n\t%s" "${ID}" "${ID_LIKE}"
      exit 1
      ;;
  esac
}

add() {
  op="add" pkg "$@"
}

del() {
  op="del" pkg "$@"
}

xxadd() {
  op="add" xx="true" pkg "$@"
}

xxdel() {
  op="del" xx="true" pkg "$@"
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

versionGTE() { test "$(printf '%s\n' "$@" | sort -V | tail -n 1)" = "$1"; }

supportRiscVGo() {
  versionGTE "$(go version | awk '{print $3}' | sed 's/^go//')" "1.14"
}

supportRiscVCGo() {
  if ! supportRiscV; then
    return 1
  fi
  versionGTE "$(go version | awk '{print $3}' | sed 's/^go//')" "1.16"
}

supportAmd64VariantGo() {
  versionGTE "$(go version | awk '{print $3}' | sed 's/^go//')" "1.18"
}

supportRC() {
  command -v llvm-rc >/dev/null 2>&1
}
