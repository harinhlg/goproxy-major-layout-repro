#!/usr/bin/env bash
set -euo pipefail

# Stamp this tree for YOUR git host and create both version tags.
#
#   keel/v3.1.0  mismatch: module line != hosted path  -> proxy .mod 404
#   keel/v3.0.0  match:    module line == hosted path  -> proxy .mod 200
#
# keel/go.mod on main always keeps the declared path
# code.invalid/atlas/keel/v3. Only the control tag rewrites it.
#
# Usage: ./setup.sh [GIT_BASE] [GOPROXY] [GOPRIVATE]
#   GIT_BASE   host/owner/repo, no /keel/v3
#              e.g. github.com/youruser/goproxy-major-layout-repro
#   GOPROXY    Go proxy base URL
#              e.g. https://artifactory.example.net/api/go/go-remote
#   GOPRIVATE  glob skipped by the checksum database
#              e.g. github.com/youruser/*

cd "$(dirname "$0")"

readonly git_base="${1:-git.example.net/demo/keelbox}"
readonly go_proxy="${2:-https://goproxy.example.net/api/go/go-remote}"
readonly go_private="${3:-*.example.net}"
readonly subdir="keel"
readonly upstream="code.invalid/atlas/keel/v3"

readonly ph_base="git.example.net/demo/keelbox"
readonly ph_proxy="https://goproxy.example.net/api/go/go-remote"
readonly ph_private="*.example.net"

readonly files=(README.md client/go.mod client/run.sh)

replace_literal() {
  local from="$1" to="$2"
  shift 2
  FROM="${from}" TO="${to}" perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g' "$@"
}

replace_literal "${ph_base}" "${git_base}" "${files[@]}"
replace_literal "${ph_proxy}" "${go_proxy}" "${files[@]}"
replace_literal "${ph_private}" "${go_private}" "${files[@]}"

[[ -d .git ]] || git init -q -b main

git add -A
if [[ -n "$(git status --porcelain 2> /dev/null)" ]]; then
  git commit -q -m "chore: point repro at ${git_base}"
fi
git tag -f "${subdir}/v3.1.0"
repro_sha="$(git rev-parse HEAD)"
readonly repro_sha

replace_literal "${upstream}" "${git_base}/${subdir}/v3" "${subdir}/go.mod"
git commit -q -a -m "chore: matching-path control for ${subdir}/v3.0.0"
git tag -f "${subdir}/v3.0.0"
git reset -q --hard "${repro_sha}"

echo "Tagged ${subdir}/v3.1.0 (mismatch -> 404) and ${subdir}/v3.0.0 (match -> 200)."
echo "Hosted module: ${git_base}/${subdir}/v3   Proxy: ${go_proxy}"
echo "Push: git push origin main && git push origin ${subdir}/v3.0.0 && git push origin ${subdir}/v3.1.0"
