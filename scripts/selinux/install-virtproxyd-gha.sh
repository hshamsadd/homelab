#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

REPO_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." &&
  pwd
)"

POLICY_SOURCE="${REPO_ROOT}/selinux/virtproxyd_gha.te"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

if [[ ! -f "$POLICY_SOURCE" ]]; then
  echo "ERROR: SELinux policy source not found: $POLICY_SOURCE" >&2
  exit 1
fi

for command_name in make semodule; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $command_name" >&2
    exit 1
  fi
done

/usr/bin/install \
  -m 0644 \
  "$POLICY_SOURCE" \
  "$BUILD_DIR/virtproxyd_gha.te"

make \
  -C "$BUILD_DIR" \
  -f /usr/share/selinux/devel/Makefile \
  virtproxyd_gha.pp

semodule \
  -X 300 \
  -i "$BUILD_DIR/virtproxyd_gha.pp"

echo "Installed SELinux module:"
semodule -lfull |
grep -F virtproxyd_gha