#!/usr/bin/env bash

add() {
  if [ -f /etc/alpine-release ]; then
    apk add "$@"
  else
    apt install -y --no-install-recommends "$@"
  fi
}

del() {
  if [ -f /etc/alpine-release ]; then
    apk del "$@" 2>/dev/null || true
  else
    apt remove --autoremove -y "$@" 2>/dev/null || true
  fi
}

xxadd() {
  if [ -f /etc/alpine-release ]; then
    xx-apk add "$@"
  else
    xx-apt install -y --no-install-recommends "$@"
  fi
}

xxdel() {
  if [ -f /etc/alpine-release ]; then
    xx-apk add "$@" 2>/dev/null || true
  else
    xx-apt install -y --autoremove "$@" 2>/dev/null || true
  fi
}
