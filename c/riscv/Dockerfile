
# tonistiigi/xx:riscv-toolchain

FROM debian:sid AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
  git build-essential file wget cpio python unzip rsync bc curl ca-certificates
  
WORKDIR /src
RUN curl -s https://buildroot.org/downloads/buildroot-2019.02.11.tar.gz | tar xvz
WORKDIR /src/buildroot-2019.02.11

ENV FORCE_UNSAFE_CONFIGURE=1
COPY config .config

RUN make -j $(nproc) && \
  mv output/host /usr/riscv64-linux-gnu && \
  rm -rf output


FROM debian:sid
COPY --from=build /usr/riscv64-linux-gnu /usr/riscv64-linux-gnu
ENV PATH=/usr/riscv64-linux-gnu/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/riscv64-linux-gnu/lib

RUN apt-get update && \
  echo "deb http://ftp.ports.debian.org/debian-ports sid main" >> /etc/apt/sources.list && \
  apt-get install -y debian-ports-archive-keyring && \
  dpkg --add-architecture riscv64 && \
  apt-get update
  
