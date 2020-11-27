group "test-detect" {
    targets = ["test-detect-alpine", "test-detect-debian"]
}

target "test-detect-alpine" {
    context = "detect"
    target = "test-alpine"
}

target "test-detect-debian" {
    context = "detect"
    target = "test-debian"
}