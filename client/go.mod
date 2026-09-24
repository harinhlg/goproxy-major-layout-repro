module client

go 1.21

// Require the declared (upstream-style) path, then replace it with the hosted
// path. setup.sh rewrites the replace target when you publish under your GitHub
// repo.
require code.invalid/atlas/keel/v3 v3.1.0

replace code.invalid/atlas/keel/v3 => github.com/harinhlg/goproxy-major-layout-repro/keel/v3 v3.1.0
