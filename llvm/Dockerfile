FROM debian:sid-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
  clang-8 lld-8 xutils-dev && \
  lndir /usr/lib/llvm-8 /usr && \
  apt-get remove -y xutils-dev


FROM alpine AS wasi-sdk
RUN apk add --no-cache curl
RUN curl -LO https://github.com/CraneStation/wasi-sdk/releases/download/wasi-sdk-5/wasi-sdk-5.0-linux.tar.gz && \
  tar xvf wasi-sdk-5.0-linux.tar.gz --strip-components=1 -C /


FROM base AS toolchain
RUN apt-get install -y --no-install-recommends \
  libgcc-8-dev-arm64-cross libc6-dev-arm64-cross \
  libgcc-8-dev-armhf-cross libc6-dev-armhf-cross

COPY --from=wasi-sdk /opt/wasi-sdk/share/sysroot /usr/wasm32-wasi
COPY --from=wasi-sdk /opt/wasi-sdk/lib/clang/8.0.0/lib/wasi/libclang_rt.builtins-wasm32.a /usr/lib/llvm-8/lib/clang/8.0.0/lib/wasi/libclang_rt.builtins-wasm32.a

RUN ln -s clang /usr/bin/wasm32-wasi-clang && \
  echo "--target=wasm32-unknown-wasi --sysroot=/usr/wasm32-wasi" > /usr/lib/llvm-8/bin/wasm32-wasi.cfg && \
  ln -s clang /usr/bin/aarch64-unknown-linux-clang && \
  echo "--target=aarch64-linux-gnu --sysroot=/usr/aarch64-linux-gnu/ -fuse-ld=lld" > /usr/lib/llvm-8/bin/aarch64-unknown-linux.cfg && \
  ln -s clang /usr/bin/arm-linux-gnueabihf-clang && \
  echo "--target=arm-linux-gnueabihf --sysroot=/usr/arm-linux-gnueabihf/ -fuse-ld=lld" > /usr/lib/llvm-8/bin/arm-linux-gnueabihf.cfg

COPY clang_wrap.sh /usr/local/sbin/clang
