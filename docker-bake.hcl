group "test" {
    targets = ["test-info-alpine", "test-info-debian"]
}

target "test-info-alpine" {
    context = "base"
    target = "test"
}

target "test-info-debian" {
    inherits = ["test-info-alpine"]
    args = {
        TEST_BASE = "debian"
    }
}
