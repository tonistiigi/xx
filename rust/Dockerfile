FROM debian:buster-slim AS base
RUN apt-get update && apt-get install -y curl clang
ADD https://sh.rustup.rs /tmp/install-rust
ENV PATH=$PATH:/root/.cargo/bin
RUN chmod +x /tmp/install-rust && \
  /tmp/install-rust -y --default-toolchain=nightly && \
  rustup target add wasm32-wasi

COPY cargo_wrap.sh /usr/local/sbin/cargo