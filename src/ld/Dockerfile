#syntax=docker/dockerfile:1
#check=error=true

ARG ALPINE_VERSION=3.21
ARG LIBTAPI_VERSION=1300.6.5
ARG CCTOOLS_VERSION=1009.2-ld64-907
ARG SIGTOOL_VERSION=c6242cb29c412168f771e97d75417e55af6cdb2e
ARG LIBDISPATCH_VERSION=swift-5.9.2-RELEASE
ARG APORTS_VERSION=3.21-stable
ARG BINUTILS_VERSION=2.43.1

FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS libtapi-base
RUN apk add --no-cache git clang lld cmake make python3 bash
COPY --link --from=xx / /
ARG LIBTAPI_VERSION
WORKDIR /work
ADD "https://github.com/tpoechtrager/apple-libtapi.git#${LIBTAPI_VERSION}" apple-libtapi
WORKDIR apple-libtapi
RUN --mount=target=/tmp/libtapi-cmake-args.patch,source=libtapi-cmake-args.patch \
    git apply /tmp/libtapi-cmake-args.patch
RUN apk add --no-cache gcc g++
RUN <<EOT
  set -ex
  NOMAKE=1 CMAKE_EXTRA_ARGS="$(xx-clang --print-cmake-defines) -DCMAKE_CXX_FLAGS=-D_LARGEFILE64_SOURCE" ./build.sh
  cd build
  make -j $(nproc) clang-tblgen llvm-tblgen
  cp -a bin/clang-tblgen bin/llvm-tblgen /usr/bin/
  cd ..
  rm -rf build
EOT

FROM libtapi-base AS libtapi
ARG TARGETPLATFORM
RUN xx-apk add g++
RUN <<EOT
  set -ex
  export INSTALLPREFIX=/opt/libtapi/
  CMAKE_EXTRA_ARGS="-DCLANG_TABLEGEN_EXE=/usr/bin/clang-tblgen -DLLVM_TABLEGEN=/usr/bin/llvm-tblgen -DCLANG_TABLEGEN=/usr/bin/clang-tblgen -DCMAKE_CXX_FLAGS=-D_LARGEFILE64_SOURCE $(xx-clang --print-cmake-defines)" ./build.sh
  ./install.sh
  xx-verify /opt/libtapi/lib/libtapi.so
  rm -rf build
EOT

FROM libtapi-base AS libtapi-static
ARG TARGETPLATFORM
RUN xx-apk add g++
RUN <<EOT
  set -x
  export INSTALLPREFIX=/opt/libtapi/
  sed -i s/SHARED/STATIC/g src/tapi/tools/libtapi/CMakeLists.txt
  CMAKE_EXTRA_ARGS="-DCLANG_TABLEGEN_EXE=/usr/bin/clang-tblgen -DLLVM_TABLEGEN=/usr/bin/llvm-tblgen -DCLANG_TABLEGEN=/usr/bin/clang-tblgen -DCMAKE_CXX_FLAGS=-D_LARGEFILE64_SOURCE $(xx-clang --print-cmake-defines)" ./build.sh
  cd build
  make -j $(nproc) LLVMObject tapiCore LLVMSupport LLVMDemangle LLVMMC  LLVMBinaryFormat tapiObjCMetadata tapiNoInits LLVMTextAPI install-tapi-headers
  mkdir /opt/libtapi/lib
  cp -a ./lib/*.a /opt/libtapi/lib/
  cd ..
  rm -rf build
EOT

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS aports
RUN apk add git
WORKDIR /work
ARG APORTS_VERSION
ADD "https://github.com/alpinelinux/aports.git#${APORTS_VERSION}" aports

FROM scratch AS patches-binutils
COPY --from=aports /work/aports/main/binutils/*.patch /

FROM scratch AS patches-libdispatch
COPY --from=aports /work/aports/community/libdispatch/*.patch /

# libdispatch is needed because alpine does not provide static library in apk
FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS libdispatch-base
RUN apk add git clang lld cmake samurai patch
ARG LIBDISPATCH_VERSION
COPY --link --from=xx / /
WORKDIR /work
ADD "https://github.com/apple/swift-corelibs-libdispatch.git#${LIBDISPATCH_VERSION}" swift-corelibs-libdispatch
WORKDIR swift-corelibs-libdispatch
RUN --mount=target=/patches,from=patches-libdispatch \
  for f in /patches/*; do patch -p1 < $f; done
ARG TARGETPLATFORM
RUN xx-apk add --no-cache gcc g++ musl-dev linux-headers bsd-compat-headers
RUN <<EOT
  set -ex
  cmake $(xx-clang --print-cmake-defines) -G Ninja -B build -DCMAKE_INSTALL_PREFIX=/out/libdispatch -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=False -DCMAKE_BUILD_TYPE=MinSizeRel
  cmake --build build
  cmake --install build
  rm -rf build
EOT
RUN ls -l /out/libdispatch/lib && [ -f /out/libdispatch/lib/libdispatch.a ] && [ -f /out/libdispatch/lib/libBlocksRuntime.a ]

FROM scratch AS libdispatch
COPY --from=libdispatch-base /out/libdispatch/lib/*.a /lib/

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS cctools-base
RUN apk add --no-cache git clang lld make llvm llvm-dev libdispatch-dev
COPY --link --from=xx / /
WORKDIR /work
ARG CCTOOLS_VERSION
ADD "https://github.com/tpoechtrager/cctools-port.git#${CCTOOLS_VERSION}" cctools-port
WORKDIR cctools-port/cctools
ARG TARGETPLATFORM
RUN --mount=target=/libdispatch,from=libdispatch \
    xx-apk add --no-cache musl-dev gcc g++ libdispatch-dev && \
    cp -a /libdispatch/. $(xx-clang --print-sysroot)usr/

FROM cctools-base AS lipo-base
ARG LIPO_CFLAGS="-Wl,-s -Os"
RUN <<EOT
  set -ex
  export CFLAGS=${LIPO_CFLAGS}
  ./configure --host=$(xx-clang --print-target-triple) LDFLAGS=--static
  make -C libmacho
  make -C libstuff
  make -C misc lipo
  xx-verify --static misc/lipo
EOT

FROM scratch AS lipo-static
COPY --from=lipo-base /work/cctools-port/cctools/misc/lipo /

FROM cctools-base AS codesign-allocate-base
ARG CODESIGN_CFLAGS="-Wl,-s -Os"
RUN <<EOT
  export CFLAGS=${CODESIGN_CFLAGS}
  ./configure --host=$(xx-clang --print-target-triple) LDFLAGS=--static
  make -C libmacho
  make -C libstuff
  make -C misc codesign_allocate
  xx-verify --static misc/codesign_allocate
EOT
FROM scratch AS codesign-allocate-static
COPY --from=codesign-allocate-base /work/cctools-port/cctools/misc/codesign_allocate /

FROM cctools-base AS ld64-static-base
# for LTO
RUN apk add llvm-dev
ARG LD64_CXXFLAGS="-Wl,-s -Os"
RUN --mount=from=libtapi-static,source=/opt/libtapi,target=/opt/libtapi <<EOT
  set -ex
  export CXXFLAGS=${LD64_CXXFLAGS}
  ./configure --with-libtapi=/opt/libtapi --host=$(xx-clang --print-target-triple)
  sed -i 's/-ltapi/-ltapi -ltapiCore -ltapiObjCMetadata -lLLVMObject -lLLVMTextAPI -lLLVMSupport -lLLVMDemangle -lLLVMMC -lLLVMBinaryFormat --static/' ld64/src/ld/Makefile
  make -j $(nproc) -C ld64
  xx-verify --static ld64/src/ld/ld
EOT
FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS sigtool-base
RUN apk add --no-cache git clang lld cmake make pkgconf
COPY --from=xx / /
WORKDIR /work
ARG SIGTOOL_VERSION
ADD "https://github.com/thefloweringash/sigtool.git#${SIGTOOL_VERSION}" sigtool
WORKDIR sigtool
RUN --mount=target=/tmp/sigtool-static.patch,source=sigtool-static.patch \
    git apply /tmp/sigtool-static.patch
ARG TARGETPLATFORM
RUN xx-apk add --no-cache g++ openssl-dev openssl-libs-static
ARG SIGTOOL_CXXFLAGS="-Wl,-s -Os"
RUN <<EOT
  set -ex
  export CXXFLAGS=${SIGTOOL_CXXFLAGS}
  mkdir build
  cd build
  cmake -DBUILD_SHARED_LIBS=False $(xx-clang --print-cmake-defines) -DCMAKE_EXE_LINKER_FLAGS=-static ..
  make -j $(nproc)
  xx-verify --static ./sigtool ./codesign
EOT

FROM scratch AS sigtool-static
COPY --link --from=codesign-allocate-static / /
COPY --link --from=sigtool-base /work/sigtool/build/sigtool /

FROM scratch AS codesign-static
COPY --link --from=codesign-allocate-static / /
COPY --link --from=sigtool-base /work/sigtool/build/codesign /

FROM scratch AS ld64-static
COPY --from=ld64-static-base /work/cctools-port/cctools/ld64/src/ld/ld /ld64

FROM scratch AS ld64-signed-static
COPY --link --from=ld64-static / /
COPY --link --from=codesign-static / /
COPY ld64.signed /

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS ld64-tgz-build
WORKDIR /work
ARG TARGETOS TARGETARCH TARGETVARIANT
RUN --mount=from=ld64-signed-static \
    mkdir /out-tgz && tar cvzf /out-tgz/ld64-signed-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz *

FROM scratch AS ld64-static-tgz
COPY --from=ld64-tgz-build /out-tgz/ /

FROM cctools-base AS cctools-build
# for LTO
RUN apk add llvm-dev
ARG CCTOOLS_CXXFLAGS="-Wl,-s -Os"
ARG CCTOOLS_CFLAGS="-Wl,-s -Os"
RUN --mount=from=libtapi,source=/opt/libtapi,target=/opt/libtapi <<EOT
  set -ex
  # copy to /usr/bin for clean rpath. TODO: try static build
  cp -a /opt/libtapi/. /usr/
  export CFLAGS=${CCTOOLS_CFLAGS} CXXFLAGS=${CCTOOLS_CXXFLAGS}
  ./configure --prefix=/opt/cctools --with-libtapi=/opt/libtapi --host=$(xx-clang --print-target-triple)
  make -j $(nproc) install
  xx-verify /opt/cctools/bin/ld
EOT

FROM scratch AS cctools
COPY --link --from=libtapi /opt/libtapi/lib/*.so /usr/lib/
COPY --link --from=cctools-build /opt/cctools /usr


FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS binutils-base0
RUN apk add --no-cache file git clang lld linux-headers zlib-dev zstd-dev gcc patch make musl-dev musl-libintl bison flex texinfo
WORKDIR /work
COPY --link --from=xx / /
COPY --link --from=patches-binutils / patches/
ARG BINUTILS_VERSION
RUN wget https://sourceware.org/pub/binutils/releases/binutils-${BINUTILS_VERSION}.tar.gz
ARG TARGETPLATFORM
# first build version for current architecture that is used then cross compiling
RUN <<EOT
  set -ex
  export CC=xx-clang CXX=xx-clang++ LD=lld BINUTILS_TARGET=${TARGETPLATFORM}
  unset TARGETPLATFORM
  tar xf binutils-${BINUTILS_VERSION}.tar.gz
  cd binutils-${BINUTILS_VERSION}
  for f in ../patches/*; do patch -p1 < $f; done
  ./configure --disable-separate-code --libdir=/lib --prefix=/usr --disable-multilib --enable-deterministic-archives --target=$(TARGETPLATFORM=$BINUTILS_TARGET xx-info) --disable-nls --disable-gprofng
  make -j $(nproc)
  make install
  cd ..
  rm -rf binutils-${BINUTILS_VERSION}
EOT
RUN xx-apk add --no-cache musl-dev gcc g++ zlib-dev zstd-dev

FROM binutils-base0 AS ld-base
RUN xx-apk add --no-cache zlib-static
ARG TARGETOS TARGETARCH TARGETVARIANT
# LD_TARGET defines platform that binutils binaries will target when run
ARG LD_TARGET=${TARGETOS}-${TARGETARCH}${TARGETVARIANT}
# LD_CFLAGS defines C compiler flags when building binutils
ARG LD_CFLAGS="-Wl,-s -Os"
# BINUTILS_CONFIG defines extra options passed to binutils configure script
ARG BINUTILS_CONFIG=
RUN <<EOT
  set -ex
  export CC=xx-clang CXX=xx-clang++ CFLAGS="$LD_CFLAGS --static" CXXFLAGS="$LD_CFLAGS" LD_TARGET_TRIPLE=$(TARGETPLATFORM= TARGETPAIR=$LD_TARGET xx-info) XX_CC_PREFER_LINKER=ld
  tar xf binutils-${BINUTILS_VERSION}.tar.gz
  cd binutils-${BINUTILS_VERSION}
  for f in ../patches/*; do patch -p1 < $f; done
  ./configure \
    --disable-separate-code \
    --libdir=/lib \
    --prefix=/ \
    --disable-multilib \
    --enable-deterministic-archives \
    --target=$LD_TARGET_TRIPLE \
    --host=$(xx-clang --print-target-triple) \
    --disable-nls \
    --disable-gold \
    --enable-relro \
    --disable-plugins \
    --with-pic \
    --with-mmap \
    --with-system-zlib \
    --disable-gas \
    --disable-elfcpp \
    --disable-binutils \
    --disable-gprofng \
    $BINUTILS_CONFIG
  make -j $(nproc)
  make install
  cd ..
  rm -rf binutils-${BINUTILS_VERSION}
  xx-verify --static /$LD_TARGET_TRIPLE/bin/ld
  mkdir -p /out
  mv /$LD_TARGET_TRIPLE/bin/ld /out/$LD_TARGET-ld
  mkdir -p /out/ldscripts
  mv /$LD_TARGET_TRIPLE/lib/ldscripts/* /out/ldscripts/
EOT
FROM ld-base AS ld-tgz-base
ARG TARGETOS TARGETARCH TARGETVARIANT
ARG LD_TARGET
WORKDIR /out
RUN mkdir /out-tgz && tar cvzf /out-tgz/$LD_TARGET-ld-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz *

FROM scratch AS ld-static
COPY --from=ld-base /out /

FROM scratch AS ld-static-tgz
COPY --from=ld-tgz-base /out-tgz/ /

FROM binutils-base0 AS binutils-base
ARG TARGETOS TARGETARCH TARGETVARIANT
# BINUTILS_TARGET defines platform that binutils binaries will target when run
ARG BINUTILS_TARGET=${TARGETOS}-${TARGETARCH}${TARGETVARIANT}
# BINUTILS_CFLAGS defines C compiler flags when building binutils
ARG BINUTILS_CFLAGS="-Wl,-s -Os"
# BINUTILS_CONFIG defines extra options passed to binutils configure script
ARG BINUTILS_CONFIG=
RUN <<EOT
  set -ex
  export CC=xx-clang CXX=xx-clang++ CFLAGS="$BINUTILS_CFLAGS" CXXFLAGS="$BINUTILS_CFLAGS"
  tar xf binutils-${BINUTILS_VERSION}.tar.gz
  cd binutils-${BINUTILS_VERSION}
  for f in ../patches/*; do patch -p1 < $f; done
  ./configure \
    --disable-separate-code \
    --libdir=/lib \
    --prefix=/out \
    --disable-multilib \
    --enable-deterministic-archives \
    --target=$(TARGETPLATFORM= TARGETPAIR=$BINUTILS_TARGET xx-info) \
    --host=$(xx-clang --print-target-triple) \
    --disable-nls \
    --enable-gold \
    --enable-relro \
    --enable-plugins \
    --with-pic \
    --with-mmap \
    --with-system-zlib \
    --disable-gprofng \
    $BINUTILS_CONFIG
  make -j $(nproc)
  make install
  cd ..
  rm -rf binutils-${BINUTILS_VERSION}
  for f in /out/bin/*; do
    if ! file "$f" | grep -q 'ASCII text'; then
      xx-verify $f
    fi
  done
EOT
FROM scratch AS binutils
COPY --from=binutils-base /out /usr/
