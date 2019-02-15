FROM --platform=$BUILDPLATFORM debian AS builder-cross
RUN dpkg --add-architecture s390x && \
  dpkg --add-architecture ppc64el && \
  dpkg --add-architecture armel && \
  dpkg --add-architecture armhf && \
  dpkg --add-architecture arm64

RUN apt-get update && apt-get install -y --no-install-recommends \
  crossbuild-essential-arm64 \
  gcc-s390x-linux-gnu g++-s390x-linux-gnu  \
  crossbuild-essential-ppc64el \
  crossbuild-essential-armel \
  crossbuild-essential-armhf \
  gcc g++ \
  libc6-dev libstdc++-6-dev \
  linux-libc-dev-arm64-cross linux-libc++-dev-arm64-cross \
  linux-libc-dev-s390x-cross linux-libc++-dev-s390x-cross \
  linux-libc-dev-ppc64el-cross linux-libc++-dev-ppc64el-cross \
  linux-libc-dev-armel-cross linux-libc++-dev-armel-cross \
  linux-libc-dev-armhf-cross linux-libc++-dev-armhf-cross

COPY wrapper.sh /usr/bin/auto-linux-gnu-g++
COPY wrapper.sh /usr/bin/auto-linux-gnu-gcc
COPY wrapper.sh /usr/bin/auto-linux-gnu-ld
COPY wrapper.sh /usr/bin/target-linux-gnu

ENV CC=auto-linux-gnu-gcc
ENV CXX=auto-linux-gnu-g++
