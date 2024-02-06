# xx - Dockerfile cross-compilation helpers

[![CI Status](https://github.com/tonistiigi/xx/workflows/build/badge.svg)](https://github.com/tonistiigi/xx/actions?query=workflow%3Abuild)
[![Docker Pulls](https://img.shields.io/docker/pulls/tonistiigi/xx.svg?logo=docker)](https://hub.docker.com/r/tonistiigi/xx/)

`xx` provides tools to support cross-compilation from Dockerfiles that understand the `--platform` flag passed in from `docker build` or `docker buildx build`. These helpers allow you to build multi-platform images from any architecture into any architecture supported by your compiler with native performance. Adding `xx` to your Dockerfile should only need minimal updates and should not require custom conditions for specific architectures.

___

* [Dockerfile cross-compilation primer](#dockerfile-cross-compilation-primer)
* [Installation](#installation)
* [Supported targets](#supported-targets)
* [`xx-info` - Information about the build context](#xx-info---information-about-the-build-context)
  * [Parsing current target](#parsing-current-target)
  * [Architecture formats](#architecture-formats)
  * [Target triple](#target-triple)
  * [Build context](#build-context)
* [`xx-apk`, `xx-apt`, `xx-apt-get` - Installing packages for target architecture](#xx-apk-xx-apt-xx-apt-get---installing-packages-for-target-architecture)
* [`xx-verify` - Verifying compilation results](#xx-verify---verifying-compilation-results)
* [C/C++](#cc)
  * [Building on Alpine](#building-on-alpine)
  * [Building on Debian](#building-on-debian)
  * [Wrapping as default](#wrapping-as-default)
* [Autotools](#autotools)
* [CMake](#cmake)
* [Go / Cgo](#go--cgo)
* [Rust](#rust)
  * [Building on Alpine](#building-on-alpine-1)
  * [Building on Debian](#building-on-debian-1)
* [External SDK support](#external-sdk-support)
* [Used by](#used-by)
* [Issues](#issues)

## Dockerfile cross-compilation primer

Cross-compilation can be achieved in Dockerfiles by using multi-stage builds and defining some of the stages to always run on the native architecture used by the builder and execute the cross-compiling compiler. By default, a Dockerfile stage started with `FROM` keyword default to the target architecture, but this can be overridden with a `FROM --platform` flag. Using [automatic platform ARGs in global scope](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope), the platform of the cross-compiler stage can be set to `$BUILDPLATFORM` while the value of `$TARGETPLATFORM` can be passed to the compiler with an environment variable.

After compilation, the resulting assets can be copied into another stage that will become the result of the build. Usually, this stage does not use `FROM --platform` so that every stage is based on the expected target architecture.

```dockerfile
FROM --platform=$BUILDPLATFORM alpine AS xbuild
ARG TARGETPLATFORM
RUN ./compile --target=$TARGETPLATFORM -o /out/myapp

FROM alpine
COPY --from=xbuild /out/myapp /bin
```

## Installation

`xx` is distributed with a Docker image `tonistiigi/xx` that contains a collection of helper scripts that read `TARGET*` environment variables to automatically configure the compilation targets. The scripts are based on Posix Shell, so they should work on top of any image but currently `xx` is expected to work on Alpine and Debian/Ubuntu based distros. In order to avoid unexpected changes, you may want to pin the image using an immutable digest. Although `xx` only contains shell scripts that are identical for every platform it is recommended to also import `xx` with `FROM --platform=$BUILDPLATFORM`, so that import commands are shared for all compilation targets.

```dockerfile
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM alpine
# copy xx scripts to your build stage
COPY --from=xx / /
# export TARGETPLATFORM (or other TARGET*)
ARG TARGETPLATFORM
# you can now call xx-* commands
RUN xx-info env
```

`xx` currently contains `xx-info`, `xx-apk`, `xx-apt-get`, `xx-cc`, `xx-c++`, `xx-clang`, `xx-clang++`, `xx-go`, `xx-cargo`, `xx-verify`. `xx-clang` (and its aliases) creates additional aliases, eg. `${triple}-clang`, `${triple}-pkg-config`, on first invocation or on `xx-clang --setup-target-triple` call.

## Supported targets

`xx` supports building from and into Linux amd64, arm64, arm/v7, s390x, ppc64le and 386, and Alpine, Debian and Ubuntu. Risc-V is supported for Go and Rust builds and for newer distros that provide Risc-V packages like `alpine:edge` or `debian:sid`.

Go builds that don't depend on system packages can additionally target MacOS and Windows on all architectures. C/C++/CGo/Rust builds are supported for MacOS targets when an external SDK image is provided.

`xx-info` command also works on RHEL-style distros but no support is provided for package manager wrappers(eg. yum, dnf) there.

## `xx-info` - Information about the build context

`xx-info` command returns normalized information about the current build context. It allows you to get various information about your build target and configuration and avoid the need for converting from one format to another in your own code. Invoking `xx-info` without any additional arguments will invoke `xx-info triple`.

### Parsing current target

- `xx-info os` - prints operating system component of TARGETPLATFORM (linux,darwin,windows,wasi)
- `xx-info arch` - architecture component of TARGETPLATFORM
- `xx-info variant`  - variant component of TARGETPLATFORM if architecture is arm (eg. v7

### Architecture formats

These commands return architecture names as used by specific tools to avoid conversion and tracking exceptions in your own code. E.g. arm64 repositories are called `aarch64` in Alpine, but `arm64` in Debian. `uname -m` returns `aarch64` in Linux, but `arm64` in Darwin etc.

- `xx-info march` - Target machine architecture that is expected to match value of `uname -m`
- `xx-info alpine-arch`  - Target architecture for [Alpine package repositories](https://pkgs.alpinelinux.org/packages)
- `xx-info debian-arch` - Target architecture for [Debian package repositories](https://www.debian.org/ports/)
- `xx-info rhel-arch` - Target architecture for [RPM package repositories](https://docs.fedoraproject.org/ro/Fedora_Draft_Documentation/0.1/html/RPM_Guide/ch01s03.html)
- `xx-info pkg-arch` - Either alpine-arch, debian-arch or rhel-arch depending on the context

### Target triple

Target triple is the target format taken as input in various gcc and llvm based compilers.

- `xx-info triple` - Target triple in arch[-vendor]-os-abi form. This command is the default.
- `xx-info vendor` - Vendor component of target triple
- `xx-info libc` - Used libc (musl or gnu)

### Build context

- `xx-info is-cross` - Exit cleanly if target is not native architecture
- `xx-info env` - Print XX_* variables defining target environment

```console
$ xx-info env
XX_OS=linux
XX_MARCH=x86_64
XX_VENDOR=alpine
XX_PKG_ARCH=x86_64
XX_TRIPLE=x86_64-alpine-linux-musl
XX_LIBC=musl
TARGETOS=linux
TARGETARCH=amd64
TARGETVARIANT=
```

## `xx-apk`, `xx-apt`, `xx-apt-get` - Installing packages for target architecture

These scripts allow managing packages (most commonly installing new packages) from either Alpine or Debian repositories. They can be invoked with any arguments regular `apk` or `apt/apt-get` commands accept. If cross-compiling for non-native architectures, the repositories for the target architecture are added automatically, and packages are installed from there. On Alpine, installing packages for a different architecture under the same root is not allowed, so `xx-apk` installs packages under a secondary root `/${triple}`. These scripts are meant for installing headers and libraries that compilers may need. To avoid unnecessary garbage, the non-native binaries under `*/bin` are skipped on installation.

```dockerfile
# alpine
ARG TARGETPLATFORM
RUN xx-apk add --no-cache musl-dev zlib-dev
```

```dockerfile
# debian
ARG TARGETPLATFORM
RUN xx-apt-get install -y libc6-dev zlib1g-dev
```

> [!NOTE]
> `xx-apt --print-source-file` can be used to print the path of the main [Apt sources configuration file](https://manpages.debian.org/bookworm/apt/sources.list.5.en.html)

Installing two meta-libraries, `xx-c-essentials`, `xx-cxx-essentials` is also allowed that expand the minimum necessary packages for either base image.

## `xx-verify` - Verifying compilation results

`xx-verify` allows verifying that the cross-compile toolchain was correctly configured and outputted binaries for the expected target platform. `xx-verify` works by calling `file` utility and comparing the expected output. Optionally `--static` option can be passed to verify that the compiler produced a static binary that can be safely copied to another Dockerfile stage without runtime libraries. If the binary does not match the expected value, `xx-verify` returns with a non-zero exit code and error message.

```dockerfile
ARG TARGETPLATFORM
RUN xx-clang --static -o /out/myapp app.c && \
    xx-verify --static /out/myapp
```

> [!NOTE]
> `XX_VERIFY_STATIC=1` environment variable can be defined to make `xx-verify`
> always verify that the compiler produced a static binary.

## C/C++

The recommended method for C-based build is to use `clang` via `xx-clang` wrapper. Clang is natively a cross-compiler, but in order to use it, you also need a linker, compiler-rt or libgcc, and a C library(musl or glibc). All these are available as packages in Alpine and Debian based distros. Clang and linker are binaries and should be installed for your build architecture, while libgcc and C library should be installed for your target architecture.

The recommended linker is `lld`, but there are some caveats. `lld` is not supported on S390x, and based on our experience, sometimes has issues with preparing static binaries for Ppc64le. In these cases, `ld` from `binutils` is required. As separate `ld` binary needs to be built for each architecture, distros often do not provide it as a package. Therefore `xx` loads [prebuilt](https://github.com/tonistiigi/xx/releases/tag/prebuilt%2Fld-1) `ld` binaries when needed. `XX_CC_PREFER_LINKER=ld` can be defined if you want to always use `ld`, even when `lld` is available on the system. Building MacOS binaries happens through a prebuilt `ld64` linker that also adds ad-hoc code-signature to the resulting binary.

`xx-clang` can be called with any arguments `clang` binary accepts and will internally call the native `clang` binary with additional configuration for correct cross-compilation. On first invocation, `xx-clang` will also set up alias commands for the current target triple that can be later called directly. This helps with tooling that looks for programs with a target triple prefix from your `PATH`. This setup phase can be manually invoked by calling `xx-clang --setup-target-triple` that is a special flag that `clang` itself does not implement.

Alias commands include:

- `triple-clang`, `triple-clang++` if `clang` is installed
- `triple-ld` if `ld` is used as linker
- `triple-pkg-config` if `pkg-config` is installed
- `triple-addr2line`, `triple-ar`, `triple-as`, `triple-ranlib`, `triple-nm`, `triple-dlltool`, `triple-strip` if cross-compilation capable tools are available though `llvm` package
- `triple-windres` if `llvm-rc` is installed and compiling for Windows

Alias commands can be called directly and always build the configuration specified by their name, even if `TARGETPLATFORM` value has changed.

### Building on Alpine

On Alpine, there is no special package for `libgcc` so you need to install `gcc` package with `xx-apk` even though the build happens through clang. To use compiler-rt instead of `libgcc` `--rtlib` needs to be passed manually. We will probably add default detection/loading for compiler-rt in the future to simplify this part. Default libc used in Alpine is [Musl](https://www.musl-libc.org/) that can be installed with `musl-dev` package.

```dockerfile
# ...
RUN apk add clang lld
# copy source
ARG TARGETPLATFORM
RUN xx-apk add gcc musl-dev
RUN xx-clang -o hello hello.c && \
    xx-verify hello
```

Clang binary can also be called directly with `--target` flag if you want to avoid `xx-` prefixes. `--print-target-triple` is a built-in flag in clang that can be used to query to correct default value.

```dockerfile
# ...
RUN xx-apk add g++
RUN clang++ --target=$(xx-clang --print-target-triple) -o hello hello.cc
```

On the first invocation, aliases with `triple-` prefix are set up so the following also works:

```dockerfile
# ...
RUN $(xx-clang --print-target-triple)-clang -o hello hello.c
```

If you prefer aliases to be created as a separate step on a separate layer, you can use `--setup-target-triple`.

```dockerfile
# ...
RUN xx-clang --setup-target-triple
RUN $(xx-info)-clang -o hello hello.c
```

### Building on Debian

Building on Debian/Ubuntu is very similar. The only required dependency that needs to be installed with `xx-apt` is `libc6-dev` or `libstdc++-N-dev` for C++.

```dockerfile
# ...
RUN apt-get update && apt-get install -y clang lld
# copy source
ARG TARGETPLATFORM
RUN xx-apt install -y libc6-dev
RUN xx-clang -o hello hello.c
```

Refer to the previous section for other variants.

If you wish to build with GCC instead of Clang you need to install `gcc` and `binutils` packages additionally with `xx-apt-get`. `xx-apt-get` will automatically install the packages that generate binaries for the current target architecture. You can then call GCC directly with the correct target triple. Note that Debian currently only provides GCC cross-compilation packages if your native platform is amd64 or arm64.

```dockerfile
# ...
# copy source
ARG TARGETPLATFORM
RUN xx-apt-get install -y binutils gcc libc6-dev
RUN $(xx-info)-gcc -o hello hello.c
```

### Wrapping as default

Special flags `xx-clang --wrap` and `xx-clang --unwrap` can be used to override the default behavior of `clang` with `xx-clang` in the extreme cases where your build scripts have no way to point to alternative compiler names.

```
# export TARGETPLATFORM=linux/amd64
# xx-clang --print-target-triple
x86_64-alpine-linux-musl
# clang --print-target-triple
x86_64-alpine-linux-musl
# 
# xx-clang --wrap
# clang --print-target-triple
x86_64-alpine-linux-musl
# xx-clang --unwrap
# clang --print-target-triple
aarch64-alpine-linux-musl
```

## Autotools

Autotools has [built-in support](https://www.gnu.org/software/automake/manual/html_node/Cross_002dCompilation.html) for cross-compilation that works by passing `--host`, `--build`, and `--target` flags to the configure script. `--host` defines the target architecture of the build result, `--build` defines compilers native architecture(used for compiling helper tools etc.), and `--target` defines an architecture that the binary returns if it is running as a compiler of other binaries. Usually, only `--host` is needed.

```dockerfile
# ...
ARG TARGETPLATFORM
RUN ./configure --host=$(xx-clang --print-target-triple) && make
```

If you need to pass `--build`, you can temporarily reset the `TARGETPLATFORM` variable to get the system value.

```dockerfile
ARG TARGETPLATFORM
RUN ./configure --host=$(xx-clang --print-target-triple) --build=$(TARGETPLATFORM= xx-clang --print-target-triple) && make
```

Sometimes `configure` scripts misbehave and don't work correctly unless the name of the C compiler is passed directly. In these cases, you can use overrides like:

```dockerfile
RUN CC=xx-clang ./configure ...
```

```dockerfile
RUN ./configure --with-cc=xx-clang ...
```

```dockerfile
RUN ./configure --with-cc=$(xx-clang --print-target-triple)-clang ...
```

## CMake

In order to make cross-compiling with CMake easier, `xx-clang` has a special flag `xx-clang --print-cmake-defines`. Running that command returns the following Cmake definitions:

```
-DCMAKE_C_COMPILER=clang
-DCMAKE_CXX_COMPILER=clang++
-DCMAKE_ASM_COMPILER=clang
-DPKG_CONFIG_EXECUTABLE="$(xx-clang --print-prog-name=pkg-config)"
-DCMAKE_C_COMPILER_TARGET="$(xx-clang --print-target-triple)"
-DCMAKE_CXX_COMPILER_TARGET="$(xx-clang++ --print-target-triple)"
-DCMAKE_ASM_COMPILER_TARGET="$(xx-clang --print-target-triple)"
```

Usually, this should be enough to pick up the correct configuration.

```dockerfile
RUN apk add cmake clang lld
ARG TARGETPLATFORM
RUN xx-apk musl-dev gcc
RUN mkdir build && cd build && \
    cmake $(xx-clang --print-cmake-defines) ..
```

## Go / Cgo

Building Go can be achieved with the `xx-go` wrapper that automatically sets up values for `GOOS`, `GOARCH`, `GOARM`, `GOAMD64` etc. It also sets up `pkg-config` and C compiler if building with CGo. Note that by default, CGo is enabled in Go when compiling for native architecture and disabled when cross-compiling. This can easily produce unexpected results; therefore, you should always define either `CGO_ENABLED=1` or `CGO_ENABLED=0` depending on if you expect your compilation to use CGo or not.

```dockerfile
FROM --platform=$BUILDPLATFORM golang:alpine
# ...
ARG TARGETPLATFORM
ENV CGO_ENABLED=0
RUN xx-go build -o hello ./hello.go && \
    xx-verify hello
```

```dockerfile
FROM --platform=$BUILDPLATFORM golang:alpine
RUN apk add clang lld
# ...
ARG TARGETPLATFORM
RUN xx-apk add musl-dev gcc
ENV CGO_ENABLED=1
RUN xx-go build -o hello ./hello.go && \
    xx-verify hello
```

If you want to make `go` compiler cross-compile by default, you can use `xx-go --wrap` and `xx-go --unwrap`

```dockerfile
# ...
RUN xx-go --wrap
RUN go build -o hello hello.go && \
    xx-verify hello
```

## Rust

Building Rust can be achieved with the `xx-cargo` wrapper that automatically
sets up the target triple and also `pkg-config` and C compiler.

The wrapper supports rust installed via [`rustup`](https://rustup.rs/)
(alpine/debian), distribution packages (alpine/debian) and the [official `rust` image](https://hub.docker.com/_/rust).

### Building on Alpine

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM rust:alpine
RUN apk add clang lld
# ...
ARG TARGETPLATFORM
RUN xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

Cargo binary can also be called directly with `--target` flag if you don't want
to use the wrapper. `--print-target-triple` is a built-in flag that can be used
to set the correct target:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM rust:alpine
RUN apk add clang lld
# ...
ARG TARGETPLATFORM
RUN cargo build --target=$(xx-cargo --print-target-triple) --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

> [!NOTE]
> `xx-cargo --print-target-triple` does not always have the same value as
> `xx-clang --print-target-triple`. This is because prebuilt Rust and C
> libraries sometimes use a different value.

The first invocation of `xx-cargo` will install the standard library for Rust
matching the target if not already installed.

To fetch dependencies from crates.io you can use `cargo fetch` before building:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM rust:alpine
RUN apk add clang lld
# ...
RUN --mount=type=cache,target=/root/.cargo/git/db \
    --mount=type=cache,target=/root/.cargo/registry/cache \
    --mount=type=cache,target=/root/.cargo/registry/index \
    cargo fetch
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/root/.cargo/git/db \
    --mount=type=cache,target=/root/.cargo/registry/cache \
    --mount=type=cache,target=/root/.cargo/registry/index \
    xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

> [!NOTE]
> By calling `cargo fetch` before `ARG TARGETPLATFORM` your packages are
> fetched only once for the whole build while the building happens separately
> for each target architecture.

To avoid redownloading dependencies on every build, you can use cache mounts
to store [Git sources with packages and metadata of crate registries](https://doc.rust-lang.org/cargo/guide/cargo-home.html#directories).

If you don't want to use the official Rust image, you can install `rustup`
manually:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM alpine AS rustup
RUN apk add curl
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --no-modify-path --profile minimal
ENV PATH="/root/.cargo/bin:$PATH"

FROM rustup
RUN apk add clang lld
# ...
ARG TARGETPLATFORM
RUN xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

If you install rust using distribution packages, `rustup` will not be available:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM alpine
RUN apk add clang lld rust cargo
# ...
ARG TARGETPLATFORM
RUN xx-apk add xx-c-essentials
RUN xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

In this case, you need to also install minimum necessary packages using `xx-apk`.

### Building on Debian

Building on Debian/Ubuntu is very similar. If you are using `rustup`:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM rust:bookworm
RUN apt-get update && apt-get install -y clang lld
ARG TARGETPLATFORM
RUN xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM debian:bookworm AS rustup
RUN apt-get update && apt-get install -y curl ca-certificates
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --no-modify-path --profile minimal
ENV PATH="/root/.cargo/bin:$PATH"

FROM rustup
RUN apt-get update && apt-get install -y clang lld
# ...
ARG TARGETPLATFORM
RUN xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

Or distribution packages:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM debian:bookworm
RUN apt-get update && apt-get install -y clang lld cargo
ARG TARGETPLATFORM
RUN xx-apt-get install xx-c-essentials
RUN xx-cargo build --release --target-dir ./build && \
    xx-verify ./build/$(xx-cargo --print-target-triple)/release/hello_cargo
```

## External SDK support

In addition to Linux targets, `xx` can also build binaries for MacOS and Windows. When building MacOS binaries from C, external MacOS SDK is needed in `/xx-sdk` directory. Such SDK can be built, for example, with [gen_sdk_package script in osxcross project](https://github.com/tpoechtrager/osxcross/blob/master/tools/gen_sdk_package.sh). Please consult XCode license terms when making such an image. `RUN --mount` syntax can be used in Dockerfile in order to avoid copying SDK files. No special tooling such as `ld64` linker is required in the image itself.

Building Windows binaries from C/CGo is currently a work in progress and not functional.

```dockerfile
# syntax=docker/dockerfile:1.2
# ...
RUN apk add clang lld
ARG TARGETPLATFORM
RUN --mount=from=my/sdk-image,target=/xx-sdk,src=/xx-sdk \
    xx-clang -o /hello hello.c && \
    xx-verify /hello

FROM scratch
COPY --from=build /hello /
```

```console
docker buildx build --platform=darwin/amd64,darwin/arm64 -o bin .
```

`-o/--output` flag can be used to export binaries out from the builder without creating a container image.

## Used by

These projects, as well as [xx Dockerfile](https://github.com/tonistiigi/xx/blob/41f7f39551857836e691da81580296ba5acf6ac3/base/Dockerfile) can be used for reference.

- [BuildKit](https://github.com/moby/buildkit/blob/8d5c5f197489f76e2663c417a9e71d42464fa3cd/Dockerfile)
- [Docker CLI](https://github.com/docker/cli/blob/86e1f04b5f115fb0b4bbd51e0e4a68233072d24b/Dockerfile)
- [Binfmt (Qemu)](https://github.com/tonistiigi/binfmt/blob/8703596e93946b9e31161c060a9ac41a8b578c3f/Dockerfile)
- [Docker Buildx](https://github.com/docker/buildx/blob/4fec647b9d8f34f8569141124d8462c912858144/Dockerfile)
- [Containerd](https://github.com/containerd/containerd/blob/9e7910ebdcbf3bf10ebd0a282ab9996572e38749/.github/workflows/release/Dockerfile)

## Issues

`xx` project welcomes contributions if you notice any issues or want to extend the capabilities with new features. We are also interested in cases where a popular project does not compile easily with `xx` so it can be improved, and tests can be added that try building these projects when `xx` gets updated. If you want to add support for a new architecture or language, please open an issue first to verify that the proposal matches the scope or `xx`.
