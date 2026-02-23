module github.com/kubernetes-sigs/contributor-site

go 1.22.4

toolchain go1.22.5

// Dependencies are pinned to specific versions (commit hashes) to ensure build
// reproducibility and stability. They are NOT updated automatically on every
// upstream commit. To update content, run 'make modules-get'.
require (
	github.com/cncf/foundation v0.0.0-20260213115547-899b0de7f20d // indirect
	github.com/kubernetes/sig-release v0.0.0-20260213154600-4664fda9dd9b // indirect
	k8s.io/community v0.0.0-20260214141759-4bea83be3fe0 // indirect
)
