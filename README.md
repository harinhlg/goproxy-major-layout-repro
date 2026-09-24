# goproxy-major-layout-repro

Original sample (not a copy of any internal tree). It is a small Go module that
a VCS-backed Go proxy should serve, but some proxies return 404 on `.mod` while
`GOPROXY=direct` succeeds.

The layout that matters:

- module source is in a **subdirectory** (`keel/`)
- module path has a **`/v3` major suffix**
- git tag is `keel/v3.x.x`
- `keel/go.mod` declares a path whose **prefix is not the git host**

That last point is normal for a fork: keep the original `module` line and consume
the clone through `replace`.

## Why direct works and some proxies fail

Go (`cmd/go` `codeRepo.findDir`) looks for `go.mod` in two places:

1. `keel/go.mod` (major version only in the module path)
2. `keel/v3/go.mod` (major version as a real directory)

It accepts (1) if the `module` line **ends with `/v3`**. It does not require the
full line to equal the path the client requested.

A proxy that requires an exact path match will reject `keel/go.mod` and then
request `keel/v3/go.mod`, which this repo never creates:

```text
GET .../contents/keel/v3/go.mod?ref=keel/v3.1.0 -> 404
```

`.info` can still be 200 (tag only). `.mod` 404s (file read).

## Two tags

| Tag           | `keel/go.mod` module line                         | Typical proxy `.mod` |
| ------------- | ------------------------------------------------- | -------------------- |
| `keel/v3.0.0` | hosted path (`GIT_BASE/keel/v3`)                  | 200                  |
| `keel/v3.1.0` | `code.invalid/atlas/keel/v3` (different prefix)   | 404                  |

`main` stays on the v3.1.0 (mismatch) commit.

## Tree

```text
keel/         published module (no keel/v3/ directory)
  go.mod      module code.invalid/atlas/keel/v3
  keel.go
client/       tiny consumer: require + replace
  go.mod
  run.sh
setup.sh      rewrite placeholders, create both tags
```

## Publish on your GitHub

Use a **new** repository name. Do not reuse names or paths from any other
environment.

```bash
cd /path/to/goproxy-major-layout-repro

./setup.sh \
  github.com/<your-user>/<your-new-repo> \
  https://<your-proxy-host>/api/go/<repo-key> \
  'github.com/<your-user>/*'

gh repo create <your-new-repo> --private --source . --remote origin --push
git push origin keel/v3.0.0
git push origin keel/v3.1.0
```

`setup.sh` argument 1 is `host/owner/repo` only. Do not append `/keel/v3`.

## Fetch

Proxy (expect `.mod` 404 on v3.1.0):

```bash
GOPRIVATE='github.com/harinhlg/*' GONOPROXY=none \
GOPROXY=https://mill.jfrog.info:12018/artifactory/api/go/go-remote-test \
  go mod download -x github.com/harinhlg/goproxy-major-layout-repro/keel/v3@v3.1.0
```

Direct (expect success):

```bash
GOPRIVATE='github.com/harinhlg/*' GONOPROXY=none GOPROXY=direct \
  go mod download -x github.com/harinhlg/goproxy-major-layout-repro/keel/v3@v3.1.0
```

`v3.0.0` is the control (proxy should return 200). Or:

```bash
cd client && ./run.sh
```

## Notes

- `replace` is how a consumer maps the declared path onto the clone. Downloading
  the hosted path with `go mod download` fails the same way if the proxy is strict.
- Any `/v2` or higher suffix is enough. `v0`/`v1` have no path suffix, so they
  never take the `keel/vN/` fallback.
