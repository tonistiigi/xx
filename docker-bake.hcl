variable "XX_REPO" {
    default = "tonistiigi/xx"
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

group "default" {
    targets = ["base-all"]
}

target "_all-platforms" {
    platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/arm/v6", "linux/ppc64le", "linux/s390x", "linux/386", "linux/riscv64"]
}

target "base" {
    context = "base"
    target = "base"
    tags = ["${XX_REPO}"]
}

target "base-all" {
    inherits = ["base", "_all-platforms"]
}