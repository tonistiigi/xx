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
        TEST_BASE = "debian"
    }
}
