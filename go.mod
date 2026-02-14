module github.com/kubernetes-sigs/contributor-site

go 1.22

// Dependencies are pinned to specific versions (commit hashes) to ensure build
// reproducibility and stability. They are NOT updated automatically on every
// upstream commit. To update content, run 'make modules-get'.
require (
	github.com/cncf/foundation v0.0.0-20260202205210-94f5c56dccf4 // indirect
	github.com/kubernetes/sig-release v0.0.0-20260202214826-624822f8822c // indirect
	k8s.io/community v0.0.0-20260203101630-a24805997f22 // indirect
)
