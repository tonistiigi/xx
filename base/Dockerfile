# syntax=docker/dockerfile:1.3-labs

ARG TEST_BASE_TYPE=alpine
ARG TEST_BASE_IMAGE=${TEST_BASE_TYPE}
ARG TEST_WITH_DARWIN=false

ARG SHADOW_VERSION=4.8.1

ARG SDKOS=${TARGETOS}

FROM --platform=$BUILDPLATFORM alpine AS scripts
COPY xx-* /out/
RUN ln -s xx-cc /out/xx-clang && \
    ln -s xx-cc /out/xx-clang++ && \
    ln -s xx-cc /out/xx-c++ && \
    ln -s xx-apt /out/xx-apt-get

FROM scratch AS base
COPY --from=scripts /out/ /usr/bin/

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS assert

FROM ${TEST_BASE_IMAGE} AS test-base-alpine
RUN --mount=type=cache,target=/pkg-cache \
    ln -s /pkg-cache /etc/apk/cache && \
    apk add bats vim
WORKDIR /work

FROM ${TEST_BASE_IMAGE} AS test-base-debian
RUN --mount=type=cache,target=/pkg-cache \
    rm -rf /var/cache/apt/archives && \
    ln -s /pkg-cache /var/cache/apt/archives && \
    rm /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "1";' > /etc/apt/apt.conf.d/keep-downloads && \
    apt update && apt install --no-install-recommends -y bats vim
WORKDIR /work

FROM ${TEST_BASE_IMAGE} AS test-base-rhel
RUN <<EOT
set -ex
if ! yum install -y epel-release; then
  if . /etc/os-release 2>/dev/null; then
    if [ "$ID" != "fedora" ]; then
      yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION:0:1}.noarch.rpm
    fi
  fi
fi
EOT
RUN --mount=type=cache,target=/pkg-cache \
    rm -rf /var/cache/yum && \
    ln -s /pkg-cache /var/cache/yum && \
    yum update -y && yum -y install bats vim
WORKDIR /work

FROM test-base-${TEST_BASE_TYPE} AS test
COPY --from=assert . .
COPY --from=base / /
COPY fixtures fixtures
COPY test-*.bats test_helper.bash .
ARG TEST_BASE_TYPE
ARG TEST_CMDS
RUN [ "${TEST_CMDS:-info}" = "${TEST_CMDS#*info}" ] && exit 0; ./test-info-common.bats && ./test-info-$(echo $TEST_BASE_TYPE | cut -d: -f1).bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-windres}" = "${TEST_CMDS#*windres}" ] && exit 0; ./test-windres.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-apk}" = "${TEST_CMDS#*apk}" ] && exit 0; [ ! -f /etc/alpine-release ] || ./test-apk.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-apt}" = "${TEST_CMDS#*apt}" ] && exit 0; [ ! -f /etc/debian_version ] || ./test-apt.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-verify}" = "${TEST_CMDS#*verify}" ] && exit 0; ./test-verify.bats
RUN --mount=type=cache,target=/pkg-cache \
    [ "${TEST_CMDS:-clang}" = "${TEST_CMDS#*clang}" ] && exit 0; ./test-clang.bats
RUN --mount=type=cache,target=/pkg-cache \
    --mount=target=/root/.cache,type=cache \
    [ "${TEST_CMDS:-golang}" = "${TEST_CMDS#*golang}" ] && exit 0; ./test-go.bats

FROM --platform=${BUILDPLATFORM} alpine AS libtapi-base
RUN apk add --no-cache git clang lld cmake python3 bash make
ARG LIBTAPI_VERSION=1100.0.11
RUN git clone https://github.com/tpoechtrager/apple-libtapi --depth 1 -b ${LIBTAPI_VERSION}
WORKDIR ./apple-libtapi
RUN --mount=target=/tmp/libtapi-cmake-args.patch,source=libtapi-cmake-args.patch \
    git apply /tmp/libtapi-cmake-args.patch
RUN apk add --no-cache gcc g++
COPY --from=base / /
RUN NOMAKE=1 CMAKE_EXTRA_ARGS="$(xx-clang --print-cmake-defines)" ./build.sh && \
    cd build && \
    make -j $(nproc) clang-tblgen llvm-tblgen tapi && \
    cp -a bin/clang-tblgen bin/llvm-tblgen bin/tapi /usr/bin/ && \
    cd .. && rm -rf build

FROM libtapi-base AS libtapi
ARG TARGETPLATFORM
RUN xx-apk add g++
RUN INSTALLPREFIX=/opt/libtapi/ \
    CMAKE_EXTRA_ARGS="-DCLANG_TABLEGEN_EXE=/usr/bin/clang-tblgen -DLLVM_TABLEGEN=/usr/bin/llvm-tblgen -DCLANG_TABLEGEN=/usr/bin/clang-tblgen $(xx-clang --print-cmake-defines)" \
    ./build.sh && ./install.sh && \
    xx-verify /opt/libtapi/lib/libtapi.so && \
    rm -rf build

FROM libtapi-base AS libtapi-static
ARG TARGETPLATFORM
RUN xx-apk add g++
RUN export INSTALLPREFIX=/opt/libtapi/ \
    CMAKE_EXTRA_ARGS="-DCLANG_TABLEGEN_EXE=/usr/bin/clang-tblgen -DLLVM_TABLEGEN=/usr/bin/llvm-tblgen -DCLANG_TABLEGEN=/usr/bin/clang-tblgen $(xx-clang --print-cmake-defines)" \
    && sed -i s/SHARED/STATIC/g src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt && \
    ./build.sh && cd build && make -j $(nproc) LLVMObject tapiCore LLVMSupport LLVMDemangle LLVMMC LLVMBinaryFormat install-tapi-headers && mkdir /opt/libtapi/lib && cp -a ./lib/*.a /opt/libtapi/lib/ && \
    cd .. && rm -rf build
    #xx-verify --static ./build/lib/libtapi.a

#FROM --platform=${BUILDPLATFORM} tonistiigi/xx:binutils-2.36.1-${TARGETOS}-${TARGETARCH}${TARGETVARIANT}-alpine AS binutils-release

FROM --platform=${BUILDPLATFORM} alpine AS cctools-base
RUN apk add --no-cache git clang lld make llvm
COPY --from=base / /
WORKDIR /work
ARG CCTOOLS_REPO=https://github.com/tpoechtrager/cctools-port
ARG CCTOOLS_VERSION=973.0.1-ld64-609
RUN git clone $CCTOOLS_REPO -b ${CCTOOLS_VERSION}
WORKDIR ./cctools-port/cctools
ARG TARGETPLATFORM
RUN xx-apk add --no-cache musl-dev gcc g++ bsd-compat-headers

FROM cctools-base AS lipo-base
ARG LIPO_CFLAGS="-Wl,-s -Os"
RUN export CFLAGS=${LIPO_CFLAGS} && \
    ./configure --host=$(xx-clang --print-target-triple) LDFLAGS=--static && \
    make -C libmacho && make -C libstuff && make -C misc lipo && \
    xx-verify --static misc/lipo

FROM scratch AS lipo-static
COPY --from=lipo-base /work/cctools-port/cctools/misc/lipo /

FROM cctools-base AS codesign-base
ARG CODESIGN_CFLAGS="-Wl,-s -Os"
RUN export CFLAGS=${CODESIGN_CFLAGS} && \
    ./configure --host=$(xx-clang --print-target-triple) LDFLAGS=--static && \
    make -C libmacho && make -C libstuff && make -C misc codesign_allocate && \
    xx-verify --static misc/codesign_allocate

FROM scratch AS codesign-static
COPY --from=codesign-base /work/cctools-port/cctools/misc/codesign_allocate /

FROM cctools-base AS otool-base
ARG OTOOL_CFLAGS="-Wl,-s -Os"
RUN export CFLAGS=${OTOOL_CFLAGS} && \
    ./configure --host=$(xx-clang --print-target-triple) LDFLAGS=--static && \
    make -C libstuff && make -C libobjc2 && make -C otool && \
    xx-verify --static otool/otool

FROM scratch AS otool-static
COPY --from=otool-base /work/cctools-port/cctools/otool/otool /

FROM cctools-base AS ld64-static-base
# for LTO
RUN apk add llvm-dev
ARG LD64_CXXFLAGS="-Wl,-s -Os"
RUN --mount=from=libtapi-static,source=/opt/libtapi,target=/opt/libtapi \
    export CXXFLAGS=${LD64_CXXFLAGS} && ./configure --with-libtapi=/opt/libtapi --host=$(xx-clang --print-target-triple) &&\
    sed -i 's/-ltapi/-ltapi -ltapiCore -lLLVMObject -lLLVMSupport -lLLVMDemangle -lLLVMMC -lLLVMBinaryFormat --static/' ld64/src/ld/Makefile && \
    make -j $(nproc) -C ld64 && \
    xx-verify --static ld64/src/ld/ld


FROM scratch AS ld64-static
COPY --from=ld64-static-base /work/cctools-port/cctools/ld64/src/ld/ld /ld64

FROM cctools-base AS cctools-build
# for LTO
RUN apk add llvm-dev
ARG CCTOOLS_CXXFLAGS="-Wl,-s -Os"
ARG CCTOOLS_CFLAGS="-Wl,-s -Os"
RUN --mount=from=libtapi,source=/opt/libtapi,target=/opt/libtapi \
    # copy to /usr/bin for clean rpath. TODO: try static build
    cp -a /opt/libtapi/. /usr/ && \ 
    export CFLAGS=${CCTOOLS_CFLAGS} CXXFLAGS=${CCTOOLS_CXXFLAGS} && \
    ./configure --prefix=/opt/cctools --with-libtapi=/opt/libtapi --host=$(xx-clang --print-target-triple) && \
    make -j $(nproc) install && \
    xx-verify /opt/cctools/bin/ld 

FROM scratch AS cctools
COPY --from=libtapi /opt/libtapi/lib/*.so /usr/lib/
COPY --from=cctools-build /opt/cctools /usr

FROM --platform=${BUILDPLATFORM} alpine AS sigtool-base
RUN apk add --no-cache git clang lld cmake make pkgconf
COPY --from=base / /
WORKDIR /work
RUN git clone https://github.com/CLIUtils/CLI11 && \
    cd CLI11 && \
    cp -a include/CLI /usr/include/ && \
    cd .. && rm -rf CLI11
ARG SIGTOOL_VERSION=1dafd2ca4651210ba9acce10d279ace22b50fb01
RUN git clone https://github.com/thefloweringash/sigtool && \
    cd sigtool && \
    git checkout ${SIGTOOL_VERSION}
WORKDIR ./sigtool
RUN --mount=target=/tmp/sigtool-static.patch,source=sigtool-static.patch \
    git apply /tmp/sigtool-static.patch
ARG TARGETPLATFORM
RUN xx-apk add --no-cache g++ openssl-dev openssl-libs-static
ARG SIGTOOL_CXXFLAGS="-Wl,-s -Os"
RUN if xx-info is-cross; then cp -a /usr/include/CLI /$(xx-info triple)/usr/include/; fi && \ 
    export CXXFLAGS=${SIGTOOL_CXXFLAGS} && \
    mkdir build && cd build && \
    cmake $(xx-clang --print-cmake-defines) -DCMAKE_EXE_LINKER_FLAGS=-static .. && \
    make -j $(nproc) && \
    xx-verify --static ./gensig

FROM scratch AS sigtool
COPY --from=codesign-static / /
COPY --from=sigtool-base /work/sigtool/build/gensig /sigtool-gensig

FROM --platform=$BUILDPLATFORM alpine AS zig-src
RUN apk add git
ARG ZIG_VERSION=0.9.0
ARG ZIG_COMMIT=a18bf7a7bfa4e8c32aa25295cfa1ca768e5f5b74
RUN <<eot
    set -ex
    git clone https://github.com/ziglang/zig
    cd zig
    git checkout "$ZIG_VERSION"
    [ -n "$ZIG_COMMIT" ] && [ "$(git rev-parse HEAD)" = "${ZIG_COMMIT}" ]
eot
WORKDIR zig
RUN <<eot
    set -ex
    for arch in aarch64 x86_64; do
        for ver in 11 12; do
            if [ ! -d "lib/libc/include/$arch-macos.$ver-gnu" ]; then continue; fi
            if [ "$arch" = "aarch64" ]; then tarch="arm64"; fi
            if [ "$arch" = "x86_64" ]; then tarch="amd64"; fi
            dir=/out/zig-$tarch-macos.$ver
            mkdir -p "$dir/usr/include"
            mkdir -p "$dir/usr/lib"
            cp -a "lib/libc/darwin/libSystem.$ver.tbd" "$dir/usr/lib/libSystem.tbd"
            cp -a "lib/libc/include/any-macos-any/." "$dir/usr/include/"
            if [ -d "lib/libc/include/any-macos.$ver-any" ]; then
                cp -a "lib/libc/include/any-macos.$ver-any/." "$dir/usr/include/"
            fi
            cp -a "lib/libc/include/$arch-macos.$ver-gnu/." "$dir/usr/include/"
            for l in libc libdbm libdl libgcc_s.1 libinfo libm libmx libpoll libproc libpthread librpcsvc; do
                ln -s libSystem.tbd "$dir/usr/lib/$l.tbd"
            done
        done
    done
eot

FROM scratch AS darwin-sdk-base
COPY --from=zig-src /out /xx-sdk/

FROM --platform=$BUILDPLATFORM alpine AS mingw-build
RUN apk add clang lld git make llvm
COPY --from=base / /
WORKDIR /src
RUN git clone https://github.com/mingw-w64/mingw-w64 && cd mingw-w64 && git checkout 586baa17bb41dd78addd8cbb6415cfd24d24e925
WORKDIR mingw-w64/mingw-w64-headers
ARG TARGETPLATFORM
ARG SDKPLATFORM=${TARGETPLATFORM}
ENV TARGETPLATFORM=${SDKPLATFORM}
RUN mkdir build && cd build && \
  ../configure --prefix=/usr/$(xx-info) --enable-idl --with-default-win32-winnt=0x601 --with-default-msvcrt=ucrt && \
  make -j $(nproc) && make install && \
  cd .. && rm -rf build

WORKDIR ../mingw-w64-crt
RUN <<eot
  set -ex
  mkdir build && cd build
  case $(xx-info arch) in
    arm)
      flags="--disable-lib32 --disable-lib64 --enable-libarm32"
    ;;
    arm64)
      flags="--disable-lib32 --disable-lib64 --enable-libarm64"
    ;;
    386)
      flags="--enable-lib32 --disable-lib64"
    ;;
    amd64)
      flags="--disable-lib32 --enable-lib64"
    ;;
  esac
  ../configure --host=$(xx-clang --print-target-triple) --prefix=/usr/$(xx-info)/ $flags --with-default-msvcrt=ucrt
  make -j $(nproc)
  make install
eot

RUN mkdir -p /out/$(xx-info) && cp -a /usr/$(xx-info)/. /out/$(xx-info)/

FROM scratch AS mingw
COPY --from=mingw-build /out /usr/

FROM mingw AS windows-sdk-base
FROM scratch AS linux-sdk-base

FROM ${SDKOS}-sdk-base AS sdk-base



FROM --platform=darwin/amd64 tonistiigi/osxcross:xx-sdk-11.1 AS sdk-extras-darwin-amd64
FROM tonistiigi/osxcross:xx-sdk-11.1 AS sdk-extras-darwin

FROM --platform=$BUILDPLATFORM alpine AS extras-base
RUN mkdir --p /out/Files/xx-sdk /out/xx-sdk

FROM scratch AS sdk-extras-linux
COPY --from=extras-base /out/Files /xx-sdk

FROM scratch AS sdk-extras-windows
COPY --from=extras-base /out /

FROM sdk-extras-linux AS sdk-extras-freebsd

FROM sdk-extras-${TARGETOS} AS sdk-extras

FROM scratch AS ld64-signed-static
COPY --from=ld64-static / /
COPY --from=sigtool / /
COPY ld64.signed /

FROM --platform=$BUILDPLATFORM alpine AS ld64-tgz-build
WORKDIR /work
ARG TARGETOS TARGETARCH TARGETVARIANT
RUN --mount=from=ld64-signed-static \
    mkdir /out-tgz && tar cvzf /out-tgz/ld64-signed-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz *

FROM scratch AS ld64-tgz
COPY --from=ld64-tgz-build /out-tgz/ /

FROM test-base-${TEST_BASE_TYPE} AS test-base-darwintrue
# COPY --from=ld64-signed-static / /usr/bin/
# COPY --from=sdk-extras-darwin-amd64 / /
COPY --from=darwin-sdk-base / /

FROM test-base-${TEST_BASE_TYPE} AS test-base-darwinfalse



# newuidmap & newgidmap binaries (shadow-uidmap 4.7-r1) shipped with alpine cannot be executed without CAP_SYS_ADMIN,
# because the binaries are built without libcap-dev.
# So we need to build the binaries with libcap enabled.
FROM --platform=$BUILDPLATFORM alpine AS idmap
RUN apk add --no-cache git autoconf automake clang lld gettext-dev libtool make byacc binutils
COPY --from=base / /
ARG SHADOW_VERSION
RUN git clone https://github.com/shadow-maint/shadow.git /shadow && cd /shadow && git checkout $SHADOW_VERSION
WORKDIR /shadow
ARG TARGETPLATFORM
RUN xx-apk add --no-cache musl-dev gcc libcap-dev
RUN CC=$(xx-clang --print-target-triple)-clang ./autogen.sh --disable-nls --disable-man --without-audit --without-selinux --without-acl --without-attr --without-tcb --without-nscd --host $(xx-clang --print-target-triple) \
  && make -j $(nproc) \
  && xx-verify src/newuidmap src/newuidmap \
  && cp src/newuidmap src/newgidmap /usr/bin

FROM scratch AS idmap-binaries
COPY --from=idmap /usr/bin/newuidmap /usr/bin/newgidmap /

FROM --platform=$BUILDPLATFORM alpine AS binutils-base0
RUN apk add --no-cache git clang lld zlib-dev gcc patch make musl-dev
WORKDIR /work
# BINUTILS_PATCHES_VERSION defines version of aports to use for patches
ARG BINUTILS_PATCHES_VERSION=3.13-stable
RUN git clone --depth 1 -b ${BINUTILS_PATCHES_VERSION} https://github.com/alpinelinux/aports.git && \
    mkdir patches && \
    cp -a aports/main/binutils/*.patch patches/ && \
    rm -rf aports
COPY --from=base / /
ARG BINUTILS_VERSION=2.36.1
RUN wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz
ARG TARGETPLATFORM
# first build version for current architecture that is used then cross compiling
RUN export CC=xx-clang CXX=xx-clang++ LD=lld BINUTILS_TARGET=${TARGETPLATFORM} && unset TARGETPLATFORM && \
    tar xf binutils-${BINUTILS_VERSION}.tar.gz && \
    cd binutils-${BINUTILS_VERSION} && \
    for f in ../patches/*; do patch -p1 < $f; done && \
    ./configure --disable-separate-code --libdir=/lib --prefix=/usr --disable-multilib --enable-deterministic-archives --target=$(TARGETPLATFORM=$BINUTILS_TARGET xx-info) --disable-nls && \
    make -j $(nproc) && \
    make install && \
    cd ..  && rm -rf binutils-${BINUTILS_VERSION}

RUN xx-apk add --no-cache musl-dev gcc g++ zlib-dev
FROM binutils-base0 AS binutils-base
ARG TARGETOS TARGETARCH TARGETVARIANT
# BINUTILS_TARGET defines platform that binutils binaries will target when run
ARG BINUTILS_TARGET=${TARGETOS}-${TARGETARCH}${TARGETVARIANT}
# BINUTILS_CFLAGS defines C compiler flags when building binutils
ARG BINUTILS_CFLAGS="-Wl,-s -Os"
# BINUTILS_CONFIG defines extra options passed to binutils configure script
ARG BINUTILS_CONFIG=
RUN export CC=xx-clang CXX=xx-clang++ CFLAGS="$BINUTILS_CFLAGS" CXXFLAGS="$BINUTILS_CFLAGS" && \
    tar xf binutils-${BINUTILS_VERSION}.tar.gz && \
    cd binutils-${BINUTILS_VERSION} && \
    for f in ../patches/*; do patch -p1 < $f; done && \
    ./configure --disable-separate-code --libdir=/lib --prefix=/out --disable-multilib --enable-deterministic-archives --target=$(TARGETPLATFORM= TARGETPAIR=$BINUTILS_TARGET xx-info) --host $(xx-clang --print-target-triple) --disable-nls --enable-gold --enable-relro --enable-plugins --with-pic --with-mmap --with-system-zlib $BINUTILS_CONFIG && \
    make -j $(nproc) && \
    make install && \
    cd ..  && rm -rf binutils-${BINUTILS_VERSION} && \
    for f in /out/bin/*; do xx-verify $f; done

FROM binutils-base0 AS ld-base
RUN xx-apk add --no-cache zlib-static
ARG TARGETOS TARGETARCH TARGETVARIANT
# LD_TARGET defines platform that binutils binaries will target when run
ARG LD_TARGET=${TARGETOS}-${TARGETARCH}${TARGETVARIANT}
# LD_CFLAGS defines C compiler flags when building binutils
ARG LD_CFLAGS="-Wl,-s -Os"
# BINUTILS_CONFIG defines extra options passed to binutils configure script
ARG BINUTILS_CONFIG=
RUN export CC=xx-clang CXX=xx-clang++ CFLAGS="$LD_CFLAGS --static" CXXFLAGS="$LD_CFLAGS" LD_TARGET_TRIPLE=$(TARGETPLATFORM= TARGETPAIR=$LD_TARGET xx-info) XX_CC_PREFER_LINKER=ld && \
    tar xf binutils-${BINUTILS_VERSION}.tar.gz && \
    cd binutils-${BINUTILS_VERSION} && \
    for f in ../patches/*; do patch -p1 < $f; done && \
    ./configure --disable-separate-code --libdir=/lib --prefix=/ --disable-multilib --enable-deterministic-archives --target=$LD_TARGET_TRIPLE --host $(xx-clang --print-target-triple) --disable-nls --disable-gold --enable-relro --disable-plugins --with-pic --with-mmap --with-system-zlib --disable-gas --disable-elfcpp --disable-binutils --disable-gprof $BINUTILS_CONFIG && \
    make -j $(nproc) && \
    make install && \
    cd ..  && rm -rf binutils-${BINUTILS_VERSION} && \
    xx-verify --static /$LD_TARGET_TRIPLE/bin/ld && \
    mkdir -p /out && mv /$LD_TARGET_TRIPLE/bin/ld /out/$LD_TARGET-ld && \
    mkdir -p /out/ldscripts && mv /$LD_TARGET_TRIPLE/lib/ldscripts/* /out/ldscripts/

FROM ld-base AS ld-tgz-base
ARG TARGETOS TARGETARCH TARGETVARIANT
ARG LD_TARGET
WORKDIR /out
RUN mkdir /out-tgz && tar cvzf /out-tgz/$LD_TARGET-ld-$TARGETOS-$TARGETARCH$TARGETVARIANT.tar.gz *

FROM scratch AS ld-static
COPY --from=ld-base /out /

FROM scratch AS ld-static-tgz
COPY --from=ld-tgz-base /out-tgz/ /

FROM --platform=$BUILDPLATFORM alpine AS compiler-rt-build
RUN apk add --no-cache git cmake clang lld make ninja python3 llvm
WORKDIR /work
COPY --from=base / /
ARG LLVM_VERSION=llvmorg-13.0.0
RUN git clone --depth 1 -b ${LLVM_VERSION} https://github.com/llvm/llvm-project.git
WORKDIR llvm-project/compiler-rt
ARG TARGETPLATFORM
ARG SDKPLATFORM=${TARGETPLATFORM}
ENV TARGETPLATFORM=${SDKPLATFORM}
COPY --from=sdk-base / /
RUN xx-apk add gcc g++ linux-headers
RUN <<eot
  set -ex
  mkdir /out
  if [ "$(xx-info arch)" = "s390x" ]; then exit 0; fi
  mkdir build && cd build
  flags="-G Ninja $(xx-clang --print-cmake-defines) -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=$(xx-info os | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON"
  case "$(xx-info os)" in
    linux)
      cmake $flags -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_BUILD_ORC=OFF -DCOMPILER_RT_BUILD_GWP_ASAN=OFF ../
    ;;
    *)
      cmake $flags -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE ../lib/builtins
    ;;
  esac
  ninja
  cp -a lib/$(xx-info os) /out/
  cd .. && rm -rf build
  find /out -type f
eot

FROM scratch AS built-compiler-rt
COPY --from=compiler-rt-build /out /usr/lib/clang/compiler-rt/

FROM built-compiler-rt AS linux-compiler-rt
FROM built-compiler-rt AS windows-compiler-rt
FROM scratch AS darwin-compiler-rt

FROM ${SDKOS}-compiler-rt AS compiler-rt

FROM --platform=$BUILDPLATFORM alpine AS libcxx-build
RUN apk add --no-cache git cmake clang lld ninja python3 llvm
WORKDIR /work
COPY --from=base / /
ARG LLVM_VERSION=llvmorg-13.0.0
RUN git clone --depth 1 -b ${LLVM_VERSION} https://github.com/llvm/llvm-project.git
WORKDIR llvm-project
ARG MACOSX_VERSION_MIN=11.0
ARG TARGETPLATFORM
ARG SDKPLATFORM=${TARGETPLATFORM}
COPY --from=sdk-base / /
COPY --from=compiler-rt / /
ENV TARGETPLATFORM=${SDKPLATFORM}
RUN xx-apk add gcc g++ linux-headers
RUN <<eot
  set -ex
  # installing compiler-rt. this should be integrated to xx
  rtpath="$(xx-clang --print-libgcc-file-name -rtlib=compiler-rt)"
  srcpath="/usr/lib/clang/compiler-rt/$(basename "$(dirname "$rtpath")")/$(basename "$rtpath")"
  ls -lR /usr/lib/clang/compiler-rt/
  if [ ! -f "$srcpath" ] || [ "$(xx-info os)" = "linux" ] && ! ls "$(dirname $srcpath)" | grep crtbegin >/dev/null; then
    echo >&2 "compilert-rt not supported in $(xx-info)"
    exit 0
  fi
  mkdir -p "$(dirname "$rtpath")"
  cp -a "$(dirname "$srcpath")/." "$(dirname "$rtpath")/"
eot
RUN <<eot
  set -ex
  if [ -f "$(xx-clang --print-libgcc-file-name -rtlib=compiler-rt)" ]; then export CFLAGS="-rtlib=compiler-rt -w"; export CXXFLAGS="-rtlib=compiler-rt -w"; fi
  mkdir build && cd build && mkdir /out
  # TODO: windows fails with libunwind
  # lld-link: error: undefined symbol: _Unwind_GetIP
  # maybe needs to be built separately?
  cmake $(xx-clang --print-cmake-defines) -DLIBCXX_HAS_MUSL_LIBC=ON -DCMAKE_CROSSCOMPILING=1 -DCMAKE_CXX_COMPILER_WORKS=1 ../runtimes/ -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DLIBUNWIND_USE_COMPILER_RT=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXXABI_USE_COMPILER_RT=ON -DCMAKE_SYSTEM_NAME=$(xx-info os | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') -DCMAKE_INSTALL_PREFIX=/out/ -G Ninja ..
  ninja install-cxx install-cxxabi install-unwind
  ls -lR /out/lib
  (xx-verify /out/lib/libc++.so.1.0 || xx-verify /out/lib/libc++.1.0.dylib)
  cd .. && rm -rf build
eot

FROM scratch AS libcxx
COPY --from=libcxx-build /out /usr/

FROM --platform=$BUILDPLATFORM alpine AS darwin-sdk-cxx-build
RUN apk add libstdc++
COPY --from=base / /
ARG MACOS_SDK_VERSION=12
COPY --from=libtapi-base /usr/bin/tapi /usr/bin
COPY --from=sdk-base / /
COPY --from=libcxx / /opt/libcxx/
ARG TARGETPLATFORM
ARG SDKPLATFORM=${TARGETPLATFORM}
ENV TARGETPLATFORM=${SDKPLATFORM}
RUN <<eot
  set -ex
  sysroot="/xx-sdk/zig-$(xx-info arch)-macos.${MACOS_SDK_VERSION}"
  for f in $(find /opt/libcxx/usr/lib -type f -name "*.dylib"); do
    name="$(echo "$(basename $f)" | cut -d . -f 1)"
    tapi stubify -o "$sysroot/usr/lib/$name.tbd" $f
  done
  cp -a /opt/libcxx/usr/include/. "$sysroot/usr/include/"
  mkdir -p /out
  cp -a "$sysroot/." /out/
eot

FROM scratch AS darwin-sdk-cxx
COPY --from=darwin-sdk-cxx-build /out/ /

FROM scratch AS linux-sdk-cxx
FROM scratch AS windows-sdk-cxx
#COPY --from=sdk-base / /
COPY --from=libcxx / /

FROM ${SDKOS}-sdk-cxx AS sdk-cxx

FROM --platform=$BUILDPLATFORM alpine AS sdk-tarball-build
COPY --from=base / /
ARG TARGETPLATFORM
ARG SDKPLATFORM=${TARGETPLATFORM}
ENV TARGETPLATFORM=${SDKPLATFORM}
ARG MACOS_SDK_VERSION=12
RUN --mount=target=/files,from=sdk-cxx <<eot
  set -ex
  mkdir -p /out
  if [ -z "$(ls -A /files)" ]; then exit 0; fi
  out="/out/$(xx-info).tar"
  if [ "$(xx-info os)" = "darwin" ]; then
    out="/out/zig-$(xx-info arch)-macos.${MACOS_SDK_VERSION}.tar"
  fi
  cd /files
  tar cvf $out .
  gzip $out
eot

FROM scratch AS sdk-tarball
COPY --from=sdk-tarball-build /out /

FROM scratch AS binutils
COPY --from=binutils-base /out /usr/

FROM base

FROM test-base-darwin${TEST_WITH_DARWIN} AS dev
COPY fixtures fixtures
COPY --from=base / /
COPY --from=compiler-rt / /
COPY --from=sdk-cxx / /sdk