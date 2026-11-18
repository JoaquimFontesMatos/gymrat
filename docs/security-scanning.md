# Security scanning

The Security scans workflow runs on pull requests and pushes to `master`.
It uses Checkov for the Dockerfile, OpenGrep for generic and supported source
rules, Sobelow for Elixir/Phoenix-specific checks, and Trivy for `mix.lock`,
asset lockfiles, configuration, and the locally built candidate image. The
image is built from the checked-out commit and is never pushed by this workflow.
No GHCR token or application secrets are used. Existing build/test and image
publishing workflows remain separate.

Findings are report-only while the baseline is reviewed; operational failures
still fail the job. Reports are uploaded as the `security-reports` Actions
artifact for seven days. Reports can contain code snippets and sensitive values;
limit access accordingly, especially when sharing results. A successful job does
not mean no findings were reported.

For local scans on Linux x86-64, install the pinned CLI releases, Sobelow and
pre-commit, then install the hook:

```sh
scripts/security/install-linux-amd64.sh "$HOME/.local/bin"
mix local.hex --force
mix escript.install hex sobelow 0.16.0 --force
# Install pre-commit using your preferred Python environment.
pre-commit install
pre-commit run --all-files
```

Ensure `$HOME/.local/bin` and `$HOME/.mix/escripts` are in `PATH`. The hook scans
the working tree, including unstaged changes, and needs network access for rules
and vulnerability databases. Its reports are written to a temporary directory
printed at the end. Outside Linux x86-64, install compatible versions of the
same tools separately. To scan a local candidate image explicitly:

```sh
docker build -t gymrat-security:local .
scripts/security/scan.sh --image gymrat-security:local
```

OpenGrep's general rules do not guarantee Elixir coverage; Sobelow supplies
Phoenix-specific checks. Trivy's Hex scan excludes development dependencies.
The homelab runs Kubescape and Falco for cluster posture and runtime monitoring,
and its manually triggered ZAP workflow tests the public applications. These
app workflows do not access the cluster or run live web tests.
