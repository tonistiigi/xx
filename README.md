## xx - Dockerfile cross-compilation helpers

`xx` provides tools to support cross-compilation from Dockerfiles that understand the `--platform` flag passed in from `docker build` or `docker buildx build`. These helpers allow you to build multi-platform images from any architecture into any architecture supported by your compiler with native performance. Adding `xx` to your Dockerfile should only need minimal updates and should not require custom conditions for specific architectures.

### Dockerfile cross-compilation primer

Cross-compilation can be achieved in Dockerfiles by using multi-stage builds and defining some of the stages to always run on the native architecture used by the builder and execute the cross-compiling compiler. By default, a Dockerfile stage started with `FROM` keyword default to the target architecture, but this can be overridden with a `FROM --platform` flag. Using [automatic platform ARGs in global scope](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope), the platform of the cross-compiler stage can be set to `$BUILDPLATFORM` while the value of `$TARGETPLATFORM` can be passed to the compiler with an environment variable.

After compilation, the resulting assets can be copied into another stage that will become the result of the build. Usually, this stage does not use `FROM --platform` so that every stage is based on the expected target architecture.

```
FROM --from=$BUILDPLATFORM alpine AS xbuild
ARG TARGETPLATFORM
RUN ./compile --target=$TARGETPLATFORM -o /out/myapp

FROM alpine
COPY --from=xbuild /out/myapp /bin
```


### Installation

`xx` is distributed with a Docker image `tonistiigi/xx` that contains a collection of helper scripts that read `TARGET*` environment variables to automatically configure the compilation targets. The scripts are based on Posix Shell, so they should work on top of any image but currently `xx` is expected to work on Alpine and Debian based distros. In order to avoid unexpected changes, you may want to pin the image using an immutable digest. Although `xx` only contains shell scripts that are identical for every platform it is recommended to also import `xx` with `FROM --platform=$BUILDPLATFORM`, so that import commands are shared for all compilation targets.

```
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM alpine
# copy xx scripts to your build stage
COPY --from=xx / /
# export TARGETPLATFORM (or other TARGET*)
ARG TARGETPLATFORM
# you can now call xx-* commands
RUN xx-info env
```

`xx` currently contains `xx-info`, `xx-apk`, `xx-apt`, `xx-cc`, `xx-c++`, `xx-clang`, `xx-clang++`, `xx-go`, `xx-verify`. `xx-clang` (and its aliases) creates additional aliases, eg. `${triple}-clang`, `${triple}-pkg-config`, on first invocation or on `xx-clang --setup-target-triple` call.

### Supported targets

`xx` supports building from and into Linux amd64, arm64, arm/v7, s390x, ppc64le and 386, and Alpine and Debian.

Go builds that don't depend on system packages can additionally target Linux Riscv64 and MacOS and Windows on all architectures. C/C++/CGo builds are supported for MacOS targets if an external SDK image is provided. 


### xx-info - Information about the build context

`xx-info` command returns normalized information about the current build context. It allows you to get various information about your build target and configuration and avoid the need for converting from one format to another in your own code.

#### Parsing current target

- `xx-info os` - prints operating system component of TARGETPLATFORM (linux,darwin,windows,wasi)
- `xx-info arch` - architecture component of TARGETPLATFORM
- `xx-info variant`  - variant component of TARGETPLATFORM if architecture is arm (eg. v7

#### Architecture formats

These commands return architecture names as used by specific tools to avoid conversion and tracking exceptions in your own code. E.g. arm64 repositories are called `aarch64` in Alpine, but `arm64` in Debian. `uname -m` returns `aarch64` in Linux, but `arm64` in Darwin etc.

- `xx-info march` - Target machine architecture that is expected to match value of `uname -m`
- `xx-info alpine-arch`  - Target architecture for [Alpine package repositories](https://pkgs.alpinelinux.org/packages)
- `xx-info debian-arch` - Target architecture for [Debian package repositories](https://www.debian.org/ports/)
- `xx-info pkg-arch` - Either alpine-arch or debian-arch depending on the context

#### Target triple

Target triple is the target format taken as input in various gcc and llvm based compilers.

- `xx-info triple` - Target triple in arch[-vendor]-os-abi form
- `xx-info vendor` - Vendor component of target triple
- `xx-info libc` - Used libc (musl or gnu)

#### Build context

- `xx-info is-cross` - Exit cleanly if target is not native architecture
- `xx-info env` - Print XX_* variables defining target environment

```
> xx-info env
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


### xx-apk, xx-apt - Installing packages for target architecture

These scripts allow managing packages (most commonly installing new packages) from either Alpine or Debian repositories. They can be invoked with any arguments regular `apk` or `apt` commands accept. If cross-compiling for non-native architectures, the repositories for the target architecture are added automatically, and packages are installed from there. On Alpine, installing packages for a different architecture under the same root is not allowed, so `xx-apt` installs packages under a secondary root `/${triple}`. These scripts are meant for installing headers and libraries that compilers may need. To avoid unnecessary garbage, the non-native binaries under `*/bin` are skipped on installation.

```
# alpine
ARG TARGETPLATFORM
RUN xx-apk add --no-cache musl-dev zlib-dev
```

```
# debian
ARG TARGETPLATFORM
RUN xx-apt install -y libc6-dev zlib1g-dev
```

Installing two meta-libraries, `xx-c-essentials`, `xx-cxx-essentials` is also allowed that expand the minimum necessary packages for either base image.

### xx-verify - Verifying compilation results

`xx-verify` allows verifying that the cross-compile toolchain was correctly configured and outputted binaries for the expected target platform. `xx-verify` works by calling `file` utility and comparing the expected output. Optionally `--static` option can be passed to verify that the compiler produced a static binary that can be safely copied to another Dockerfile stage without runtime libraries. If the binary does not match the expected value `xx-verify` returns with a non-zero exit code and error message.

```
ARG TARGETPLATFORM
RUN xx-clang --static -o /out/myapp app.c && \
    xx-verify --static /out/myapp
```

### C/C++

### Autotools

### CMake

### Go / Cgo

### External SDK support

### Used by

These projects, as well as [xx Dockerfile](https://github.com/tonistiigi/xx/blob/41f7f39551857836e691da81580296ba5acf6ac3/base/Dockerfile) can be used for reference.

- [BuildKit](https://github.com/moby/buildkit/blob/8d5c5f197489f76e2663c417a9e71d42464fa3cd/Dockerfile)
- [Docker CLI](https://github.com/docker/cli/blob/86e1f04b5f115fb0b4bbd51e0e4a68233072d24b/Dockerfile)
- [Binfmt (Qemu)](https://github.com/tonistiigi/binfmt/blob/8703596e93946b9e31161c060a9ac41a8b578c3f/Dockerfile)
- [Docker Buildx](https://github.com/docker/buildx/blob/4fec647b9d8f34f8569141124d8462c912858144/Dockerfile)

### Issues
