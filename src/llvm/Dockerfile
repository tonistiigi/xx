#syntax=docker/dockerfile:1.8
#check=error=true

FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM alpine AS compiler-rt-build
RUN apk add --no-cache git cmake clang lld make ninja python3 llvm
WORKDIR /work
COPY --from=xx / /
ARG LLVM_VERSION=llvmorg-11.0.1
RUN git clone --depth 1 -b ${LLVM_VERSION} https://github.com/llvm/llvm-project.git
WORKDIR llvm-project/compiler-rt
ARG TARGETPLATFORM
RUN xx-apk add gcc g++
RUN mkdir build && cd build && \
    cmake $(xx-clang --print-cmake-defines) -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=OFF -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON -DCMAKE_SYSTEM_NAME=$(xx-info os | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') -DCMAKE_LIPO=/usr/bin/llvm-lipo -G Ninja .. && \
    ninja && mkdir /out && cp -a lib/linux /out/ && \
    cd .. && rm -rf build

FROM scratch AS compiler-rt
COPY --from=compiler-rt-build /out /usr/lib/clang/compiler-rt/

FROM --platform=$BUILDPLATFORM alpine AS libcxx-build
RUN apk add --no-cache git cmake clang lld make ninja python3 binutils
WORKDIR /work
COPY --from=xx / /
ARG LLVM_VERSION=llvmorg-11.0.1
RUN git clone --depth 1 -b ${LLVM_VERSION} https://github.com/llvm/llvm-project.git
WORKDIR llvm-project/libcxx
ARG LIBCXX_TARGET
ENV TARGETPLATFORM=${LIBCXX_TARGET}
RUN xx-apk -v add gcc g++ linux-headers
RUN mkdir build && cd build && \
    cmake $(xx-clang --print-cmake-defines) -DLIBCXX_HAS_MUSL_LIBC=ON -G Ninja .. && \
    ninja && mkdir /out && cp -a lib/libc++* /out/ && \
    xx-verify /out/libc++.so && \
    cd .. && rm -rf build

FROM scratch AS libcxx
COPY --from=libcxx-build /out /usr/lib/
