variable "XX_REPO" {
    default = "tonistiigi/xx"
}

variable "TEST_BASE_TYPE" {
    default = "alpine"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
    tags = ["${XX_REPO}:test"]
}

target "test-src" {
    context = "src"
}

target "test-alpine" {
    inherits = ["test-src"]
}

target "test-debian" {
    inherits = ["test-src"]
    args = {
        APT_MIRROR = "cdn-fastly.deb.debian.org"
        TEST_BASE_TYPE = "debian"
        TEST_BASE_IMAGE = "debian:bullseye"
    }
}

target "test-rhel" {
    inherits = ["test-src"]
    args = {
        TEST_BASE_TYPE = "rhel"
        TEST_BASE_IMAGE = "fedora:35"
    }
}

target "test-base" {
  inherits = ["test-${TEST_BASE_TYPE}"]
}

group "test" {
  targets = [
    "test-info",
    "test-apk",
    "test-apt",
    "test-verify",
    "test-clang",
    "test-go",
    "test-cargo"
  ]
}

target "test-info" {
  inherits = ["test-base"]
  target = "test-info"
}

target "test-apk" {
  inherits = ["test-base"]
  target = "test-apk"
}

target "test-apt" {
  inherits = ["test-base"]
  target = "test-apt"
}

target "test-verify" {
  inherits = ["test-base"]
  target = "test-verify"
}

target "test-clang" {
  inherits = ["test-base"]
  target = "test-clang"
}

target "test-go" {
  inherits = ["test-base"]
  target = "test-go"
}

target "test-cargo" {
  inherits = ["test-base"]
  target = "test-cargo"
}

group "validate" {
    targets = ["shfmt-validate", "shellcheck"]
}

target "shfmt-validate" {
    dockerfile = "./hack/dockerfiles/shfmt.Dockerfile"
    target = "validate"
    output = ["type=cacheonly"]
}

target "shfmt" {
    dockerfile = "./hack/dockerfiles/shfmt.Dockerfile"
    target = "update"
    output = ["."]
}

target "shellcheck" {
    dockerfile = "./hack/dockerfiles/shellcheck.Dockerfile"
    output = ["type=cacheonly"]
}

group "default" {
    targets = ["base-all"]
}

target "_all-platforms" {
    platforms = [
        "linux/386",
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v5",
        "linux/arm/v6",
        "linux/arm/v7",
        "linux/mips",
        "linux/mipsle",
        "linux/mips64",
        "linux/mips64le",
        "linux/ppc64le",
        "linux/s390x",
        "linux/riscv64"
    ]
}

target "xx" {
    inherits = ["meta-helper"]
    context = "src"
    target = "xx"
}

target "xx-all" {
    inherits = ["xx", "_all-platforms"]
}

target "sdk-extras" {
    context = "src/sdk-extras"
    target = "sdk-extras"
    tags = ["${XX_REPO}:sdk-extras"]
    platforms = [
        "darwin/amd64",
        "darwin/arm64",
        "freebsd/amd64",
        "linux/386",
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v5",
        "linux/arm/v6",
        "linux/arm/v7",
        "linux/mips",
        "linux/mipsle",
        "linux/mips64",
        "linux/mips64le",
        "linux/ppc64le",
        "linux/riscv64",
        "linux/s390x",
        "windows/386",
        "windows/amd64",
        "windows/arm",
        "windows/arm64"
    ]
}

target "_ld-base" {
    context = "src/ld"
    contexts = {
        "tonistiigi/xx" = "target:xx"
    }
}

target "ld64-tgz" {
    inherits = ["_ld-base"]
    target = "ld64-tgz"
    output = ["./ld64-tgz"]
    platforms = [
        "linux/386",
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v6",
        "linux/arm/v7"
    ]
    cache-to = ["type=inline"]
}

variable "BINUTILS_VERSION_ONLY" {
    default = ""
}

variable "BINUTILS_VERSION" {
    default = "2.36.1"
}

function "binutilsTag" {
    # this can be cleaned up in newer buildx
    params = [repo, version, version_only, target]
    result = ["${repo}:binutils-${version}-${target}-alpine", version_only=="1"?"":"${repo}:binutils-${target}-alpine"]
} 

group "binutils" {
    targets = [for v in ["linux-arm64", "linux-amd64", "linux-riscv64", "linux-s390x", "linux-armv6", "linux-armv7", "linux-ppc64le", "linux-386", "windows-amd64", "windows-386"]: "binutils-${v}-alpine"]
}

target "binutils-base" {
    inherits = ["_ld-base"]
    target = "binutils"
    args = {
        BINUTILS_VERSION = BINUTILS_VERSION
    }
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm",
        "linux/s390x"
    ]
    cache-to = ["type=inline"]
}

target "binutils-linux-arm64-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-arm64"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-arm64")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-arm64")[0]])]
}

target "binutils-linux-amd64-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-amd64"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-amd64")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-amd64")[0]])]
}

target "binutils-linux-armv7-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-armv7"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-armv7")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-armv7")[0]])]
}

target "binutils-linux-armv6-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-armv6"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-armv6")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-armv6")[0]])]
}

target "binutils-linux-ppc64le-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-ppc64le"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-ppc64le")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-ppc64le")[0]])]
}

target "binutils-linux-386-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-386"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-386")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-386")[0]])]
}

target "binutils-linux-riscv64-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-riscv64"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-riscv64")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-riscv64")[0]])]
}

target "binutils-linux-s390x-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "linux-s390x"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-s390x")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "linux-s390x")[0]])]
}

target "binutils-windows-amd64-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "windows-amd64"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "windows-amd64")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "windows-amd64")[0]])]
}

target "binutils-windows-386-alpine" {
    inherits = ["binutils-base"]
    args = {
        BINUTILS_TARGET = "windows-386"
    }
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "windows-386")
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, "windows-386")[0]])]
}

group "ld-static-tgz" {
    targets = [for v in ["linux-arm64", "linux-amd64", "linux-riscv64", "linux-s390x", "linux-armv6", "linux-armv7", "linux-ppc64le", "linux-386", "windows-amd64", "windows-386"]: "ld-${v}-tgz"]
}

target "ld-tgz-base" {
    inherits = ["_ld-base"]
    target = "ld-static-tgz"
    args = {
        LD_VERSION = BINUTILS_VERSION
    }
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm",
        "linux/s390x",
        "linux/ppc64le"
    ]
    cache-to = ["type=inline"]
    output = ["./ld-tgz"]
}

target "ld-linux-arm64-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-arm64"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-arm64")[0]])]
}

target "ld-linux-amd64-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-amd64"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-amd64")[0]])]
}

target "ld-linux-armv7-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-armv7"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-armv7")[0]])]
}

target "ld-linux-armv6-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-armv6"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-armv6")[0]])]
}

target "ld-linux-386-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-386"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-386")[0]])]
}

target "ld-linux-ppc64le-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-ppc64le"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-ppc64le")[0]])]
}

target "ld-linux-s390x-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-s390x"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-s390x")[0]])]
}

target "ld-linux-riscv64-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "linux-riscv64"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "linux-riscv64")[0]])]
}

target "ld-windows-amd64-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "windows-amd64"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "windows-amd64")[0]])]
}

target "ld-windows-386-tgz" {
    inherits = ["ld-tgz-base"]
    args = {
        LD_TARGET = "windows-386"
    }
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", "windows-386")[0]])]
}

target "compiler-rt" {
    context = "src/llvm"
    contexts = {
        "tonistiigi/xx" = "target:xx"
    }
    target = "compiler-rt"
    platforms = [
        "linux/amd64",
        "linux/arm64",
    ]
}

target "libcxx" {
    context = "src/llvm"
    contexts = {
        "tonistiigi/xx" = "target:xx"
    }
    target = "libcxx"
    platforms = [
        "linux/amd64",
        "linux/arm64",
    ]
}