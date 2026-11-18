#!/usr/bin/env bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
mode=${1:---source}
report_dir=${SECURITY_REPORT_DIR:-}
if [[ -z "$report_dir" ]]; then
  report_dir=$(mktemp -d "${TMPDIR:-/tmp}/app-security-report.XXXXXXXX") || exit 1
fi
mkdir -p "$report_dir" || exit 1
report_dir=$(cd "$report_dir" && pwd) || exit 1
status=0
run_scan() {
  local label=$1
  shift
  printf 'Running %s...\n' "$label"
  if "$@"; then
    printf '%s completed.\n' "$label"
  else
    printf '%s failed to run successfully.\n' "$label" >&2
    status=1
  fi
}
run_scan_to_file() {
  local label=$1 output=$2
  shift 2
  printf 'Running %s...\n' "$label"
  if "$@" > "$output"; then
    printf '%s completed.\n' "$label"
  else
    printf '%s failed to run successfully.\n' "$label" >&2
    status=1
  fi
}
case "$mode" in
  --source)
    for tool in checkov opengrep sobelow trivy; do
      if ! command -v "$tool" >/dev/null; then
        printf 'Missing %s; see docs/security-scanning.md\n' "$tool" >&2
        status=1
      fi
    done
    if (( status != 0 )); then exit "$status"; fi
    run_scan_to_file Checkov "$report_dir/checkov.json" checkov -f Dockerfile --framework dockerfile --soft-fail --skip-download --output json
    run_scan OpenGrep opengrep scan --config p/default --json --output "$report_dir/opengrep.json" .
    if [[ -f "$report_dir/opengrep.json" ]]; then
      if ! python3 scripts/security/check-opengrep-report.py "$report_dir/opengrep.json"; then
        status=1
      fi
    fi
    run_scan_to_file Sobelow "$report_dir/sobelow.json" sobelow --private --format json
    run_scan Trivy-filesystem trivy fs --scanners vuln,misconfig --exit-code 0 --format json --output "$report_dir/trivy-fs.json" .
    ;;
  --image)
    image=${2:?Pass a locally built image name}
    command -v trivy >/dev/null || { echo 'Missing trivy; see docs/security-scanning.md' >&2; exit 1; }
    run_scan Trivy-image trivy image --exit-code 0 --format json --output "$report_dir/trivy-image.json" "$image"
    ;;
  *) echo 'Usage: scan.sh [--source | --image IMAGE]' >&2; exit 2 ;;
esac
printf 'Reports: %s\n' "$report_dir"
exit "$status"
