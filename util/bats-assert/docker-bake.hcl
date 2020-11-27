variable "TARGET_REPO" {
    default = "tonistiigi/bats-assert"
}

target "default" {
    tags = ["${TARGET_REPO}"]
    cache-to = ["type=inline"]
    cache-from = ["${TARGET_REPO}"]
}

target "all" {
    inherits = ["default"]
    platforms = [
        "linux/amd64",
        "linux/arm64",
        "linux/arm/v7",
        "linux/arm/v6",
        "linux/arm/v5",
        "linux/386",
        "linux/riscv64",
        "linux/s390x",
        "linux/ppc64le"
    ]
}

target "test" {
    target = "test"
}

target "generate-golden" {
    target = "golden"
    output = [
        "."
    ]
}