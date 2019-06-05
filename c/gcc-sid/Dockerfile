
# tonistiigi/xx:gcc-sid

FROM --platform=$BUILDPLATFORM debian:sid AS builder-cross
RUN dpkg --add-architecture s390x && \
  dpkg --add-architecture ppc64el && \
  dpkg --add-architecture armel && \
  dpkg --add-architecture armhf && \
  dpkg --add-architecture arm64 && \
  dpkg --add-architecture riscv64

# add ports in case user wants to apt-get riscv64 libraries
RUN apt-get update && \
  echo "deb http://ftp.ports.debian.org/debian-ports sid main" >> /etc/apt/sources.list && \
  apt-get install -y debian-ports-archive-keyring && \
  apt-get update

RUN apt-get install -y --no-install-recommends \
  crossbuild-essential-arm64 \
  gcc-s390x-linux-gnu g++-s390x-linux-gnu  \
  crossbuild-essential-ppc64el \
  crossbuild-essential-armel \
  crossbuild-essential-armhf \
  gcc-riscv64-linux-gnu g++-riscv64-linux-gnu  \
  gcc g++ \
  libc6-dev libstdc++-8-dev \
  linux-libc-dev-arm64-cross linux-libc++-dev-arm64-cross \
  linux-libc-dev-s390x-cross linux-libc++-dev-s390x-cross \
  linux-libc-dev-ppc64el-cross linux-libc++-dev-ppc64el-cross \
  linux-libc-dev-armel-cross linux-libc++-dev-armel-cross \
  linux-libc-dev-armhf-cross linux-libc++-dev-armhf-cross\
  linux-libc-dev-riscv64-cross linux-libc++-dev-riscv64-cross

# TODO: add sysroot switch instead
COPY wrapper.sh /usr/bin/auto-linux-gnu-g++
COPY wrapper.sh /usr/bin/auto-linux-gnu-gcc
COPY wrapper.sh /usr/bin/auto-linux-gnu-ld
COPY wrapper.sh /usr/bin/target-linux-gnu

ENV CC=auto-linux-gnu-gcc
ENV CXX=auto-linux-gnu-g++