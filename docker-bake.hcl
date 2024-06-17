variable "XX_REPO" {
    default = "tonistiigi/xx"
}

variable "TEST_BASE_TYPE" {
    default = "alpine"
}

variable "TEST_BASE_IMAGE" {
    default = TEST_BASE_TYPE == "alpine" ? "alpine:3.19" : TEST_BASE_TYPE == "debian" ? "debian:bookworm" : TEST_BASE_TYPE == "rhel" ? "fedora:39" : null
}

variable "DEV_SDK_PLATFORM" {
    default = null
}

variable "DEV_WITH_LD64" {}

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
        TEST_BASE_TYPE = "debian"
        TEST_BASE_IMAGE = "debian:bookworm"
    }
}

target "test-rhel" {
    inherits = ["test-src"]
    args = {
        TEST_BASE_TYPE = "rhel"
        TEST_BASE_IMAGE = "fedora:40"
    }
}

target "test-base" {
    inherits = ["test-${TEST_BASE_TYPE}"]
    output = ["type=cacheonly"]
}

group "test" {
    targets = [
        "test-info",
        "test-apk",
        "test-apt",
        "test-dnf",
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

target "test-dnf" {
    inherits = ["test-base"]
    target = "test-dnf"
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
    targets = ["xx-all"]
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

target "sdk-extras-dev" {
    inherits = ["sdk-extras"]
    platforms = DEV_SDK_PLATFORM == null ? null : [ DEV_SDK_PLATFORM ]
}

target "_ld-base" {
    context = "src/ld"
    contexts = {
        "tonistiigi/xx" = "target:xx"
    }
}

variable "BINUTILS_VERSION_ONLY" {
    default = ""
}

variable "BINUTILS_VERSION" {
    default = "2.42"
}

function "binutilsTag" {
    # this can be cleaned up in newer buildx
    params = [repo, version, version_only, target]
    result = ["${repo}:binutils-${version}-${target}-alpine", version_only=="1"?"":"${repo}:binutils-${target}-alpine"]
} 

target "binutils" {
    name = "binutils-${tgt}-alpine"
    inherits = ["_ld-base"]
    matrix = {
        tgt = [
            "linux-386",
            "linux-amd64",
            "linux-arm64",
            "linux-armv6",
            "linux-armv7",
            "linux-ppc64le",
            "linux-riscv64",
            "linux-s390x",
            "windows-386",
            "windows-amd64"
        ]
    }
    target = "binutils"
    args = {
        BINUTILS_VERSION = BINUTILS_VERSION
        BINUTILS_TARGET = tgt
    }
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm",
        "linux/s390x"
    ]
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, tgt)[0]])]
    cache-to = ["type=inline"]
    tags = binutilsTag(XX_REPO, BINUTILS_VERSION, BINUTILS_VERSION_ONLY, tgt)
}

target "ld64" {
    inherits = ["_ld-base"]
    target = "ld64-signed-static"
}

target "ld64-static-tgz" {
    inherits = ["ld64"]
    platforms = [
        "linux/386",
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v7",
    ]
    output = ["./bin/ld-static-tgz"]
    target = "ld64-static-tgz"
}

target "ld-static-tgz" {
    name = "ld-${tgt}-static-tgz"
    inherits = ["_ld-base"]
    matrix = {
        tgt = [
            "linux-386",
            "linux-amd64",
            "linux-arm64",
            "linux-armv6",
            "linux-armv7",
            "linux-ppc64le",
            "linux-riscv64",
            "linux-s390x",
            "windows-386",
            "windows-amd64"
        ]
    }
    target = "ld-static-tgz"
    args = {
        BINUTILS_VERSION = BINUTILS_VERSION
        LD_TARGET = tgt
    }
    platforms = [
        "linux/386",
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v6",
        "linux/arm/v7",
        "linux/s390x",
        "linux/ppc64le"
    ]
    cache-from = [join("", ["type=registry,ref=", binutilsTag(XX_REPO, BINUTILS_VERSION, "1", tgt)[0]])]
    cache-to = ["type=inline"]
    output = ["./bin/ld-static-tgz"]
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

target "dev" {
    context = "src"
    target = "dev"
    contexts = {
        "tonistiigi/xx" = "target:xx"
        "sdk-extras" = DEV_SDK_PLATFORM != null ? "target:sdk-extras-dev" : "docker-image://scratch"
        "ld64" = DEV_WITH_LD64 != "" ? "target:ld64" : "docker-image://scratch"
    }
    args = {
        TEST_BASE_TYPE = TEST_BASE_TYPE
        TEST_BASE_IMAGE = TEST_BASE_IMAGE
    }
    tags = [ "${XX_REPO}:dev" ]
    output = [
        "type=docker"
    ]
}

target "lipo" {
    context = "src/ld"
    target = "lipo-static"
    contexts = {
        "tonistiigi/xx" = "target:xx"
    }
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v7",
    ]
}

target "sigtool" {
    context = "src/ld"
    target = "sigtool-static"
    contexts = {
        "tonistiigi/xx" = "target:xx"
    }
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v7",
    ]
}
