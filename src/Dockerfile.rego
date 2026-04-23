package docker

default allow := false

decision := {"allow": allow}

test_matrix := [
	"centos",
	"debian",
	"fedora",
	"oraclelinux",
	"redhat/ubi8",
	"rockylinux/rockylinux",
	"ubuntu",
]

allow if {
	input.local
	not input.env.args.release == "1"
}

allow if {
	input.git.remote == "https://github.com/tonistiigi/xx.git"
}

allow if {
	input.image.repo == "docker/dockerfile"
	docker_github_builder(input.image, "moby/buildkit")
	every sig in input.image.signatures {
		startswith(sig.signer.sourceRepositoryRef, "refs/tags/dockerfile/")
		some ts in sig.timestamps
		ts.type == "Tlog"
	}
}

allow if input.image.repo == "alpine"

allow if {
	input.image.repo in test_matrix
	startswith(input.env.target, "test-")
}

allow if {
	input.image.repo in test_matrix
	input.env.target == "dev"
}

# dev helpers
allow if {
	input.image.repo == "tonistiigi/bats-assert"
}

allow if {
	input.http.url == "https://raw.githubusercontent.com/fsaintjacques/semver-tool/3.4.0/src/semver"
	input.http.checksum == "sha256:1ff4a97e4d1e389f6f034f7464ac4365f1be2d900e2dc2121e24a6dc239e8991"
}

allow if {
	input.git.remote == "https://github.com/bats-core/bats-core.git"
	input.git.tagName == "v1.13.0"
	input.git.checksum == "d6a46f2cc2d3025ee3ffb59991c6d93ef903e339"
}
