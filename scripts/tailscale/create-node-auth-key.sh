#!/usr/bin/env bash
set -euo pipefail

DEVICE_TAG="${1:-}"

case "$DEVICE_TAG" in
  tag:infra-server|\
  tag:k3s-control-plane|\
  tag:k3s-worker|\
  tag:app-server)
    ;;
  *)
    echo "Unsupported Tailscale device tag: ${DEVICE_TAG}" >&2
    echo "Allowed tags:" >&2
    echo "  tag:infra-server" >&2
    echo "  tag:k3s-control-plane" >&2
    echo "  tag:k3s-worker" >&2
    echo "  tag:app-server" >&2
    exit 2
    ;;
esac

: "${TS_API_CLIENT_ID:?TS_API_CLIENT_ID is required}"
: "${TS_API_CLIENT_SECRET:?TS_API_CLIENT_SECRET is required}"

if command -v tailscale-get-authkey >/dev/null 2>&1; then
  GET_AUTHKEY_BIN="$(command -v tailscale-get-authkey)"
elif command -v get-authkey >/dev/null 2>&1; then
  GET_AUTHKEY_BIN="$(command -v get-authkey)"
else
  echo "tailscale-get-authkey is not installed or available in PATH." >&2
  exit 1
fi

exec "$GET_AUTHKEY_BIN" \
  -tags "$DEVICE_TAG" \
  -preauth=true \
  -reusable=false \
  -ephemeral=false
