group "test-detect" {
    targets = ["test-detect-alpine"]
}

target "test-detect-alpine" {
    context = "detect"
    dockerfile = "Dockerfile"
    target = "test-alpine"
}