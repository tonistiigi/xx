variable "XX_REPO" {
    default = "tonistiigi/xx"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
    tags = ["${XX_REPO}:test"]
}

group "test" {
    targets = ["test-alpine", "test-debian"]
}

target "test-alpine" {
    context = "base"
    target = "test"
}

target "test-debian" {
    inherits = ["test-alpine"]
    args = {
        TEST_BASE_TYPE = "debian"
        TEST_BASE_IMAGE = "debian:bullseye"
    }
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
    platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/arm/v6", "linux/ppc64le", "linux/s390x", "linux/386", "linux/riscv64"]
}

target "base" {
    inherits = ["meta-helper"]
    context = "base"
    target = "base"
}

target "base-all" {
    inherits = ["base", "_all-platforms"]
}

target "sdk-extras" {
    context = "base"
    target = "sdk-extras"
    tags = ["${XX_REPO}:sdk-extras"]
    platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/arm/v6", "linux/ppc64le", "linux/s390x", "linux/386", "linux/riscv64", "windows/amd64", "windows/arm", "windows/386", "windows/arm64", "linux/mips64", "linux/mips64le", "darwin/amd64", "darwin/arm64", "freebsd/amd64"]
}

target "ld64-tgz" {
    context = "base"
    target = "ld64-tgz"
    output = ["./ld64-tgz"]
    platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/arm/v6", "linux/386"]
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
    context = "base"
    target = "binutils"
    args = {
        BINUTILS_VERSION = BINUTILS_VERSION
    }
    platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/s390x"]
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
    context = "base"
    target = "ld-static-tgz"
    args = {
        LD_VERSION = BINUTILS_VERSION
    }
    platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/s390x", "linux/ppc64le"]
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
