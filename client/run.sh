#!/usr/bin/env bash
set -euo pipefail

# Fetch the hosted module first with GOPROXY=direct (should work), then through
# a Go module proxy (Artifactory is expected to 404 on .mod for v3.1.0).
#
# v3.1.0: go.mod module line does not equal the hosted path (reproduces 404).
# v3.0.0: go.mod module line equals the hosted path (control, 200).

cd "$(dirname "$0")"

readonly module="github.com/harinhlg/goproxy-major-layout-repro/keel/v3@v3.1.0"

tmpdir=$(mktemp -d)
trap 'chmod -R u+w "${tmpdir}" && rm -rf "${tmpdir}"' EXIT

export GO111MODULE="on"
export GOPRIVATE="github.com/harinhlg/*"
export GONOPROXY="none"
export GOMODCACHE="${tmpdir}"

echo "==> GOPROXY=direct (expected OK)"
GOPROXY="direct" go mod download -x "${module}" && echo "direct: OK"

echo
echo "==> Through Go proxy (expected FAIL: 404 on .mod for v3.1.0)"
export GOPROXY="https://mill.jfrog.info:12018/artifactory/api/go/go-remote-test"
go mod download -x "${module}"
