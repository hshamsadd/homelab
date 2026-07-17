#!/usr/bin/env bash
set -euo pipefail

PUBLIC_KEY_FILE="${1:-}"
VALID_PRINCIPALS="${2:-}"
TTL="${3:-30m}"

if [[ -z "$PUBLIC_KEY_FILE" || ! -f "$PUBLIC_KEY_FILE" ]]; then
  echo "Usage: $0 PUBLIC_KEY_FILE VALID_PRINCIPALS [TTL]" >&2
  exit 2
fi

if [[ -z "$VALID_PRINCIPALS" ]]; then
  echo "At least one SSH principal is required." >&2
  exit 2
fi

: "${VAULT_ADDR:?VAULT_ADDR is required}"
: "${VAULT_TOKEN:?VAULT_TOKEN is required}"

REQUEST_FILE="$(mktemp)"
RESPONSE_FILE="$(mktemp)"

cleanup() {
  rm -f "$REQUEST_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

jq -n \
  --arg public_key "$(cat "$PUBLIC_KEY_FILE")" \
  --arg valid_principals "$VALID_PRINCIPALS" \
  --arg ttl "$TTL" \
  '{
    public_key: $public_key,
    valid_principals: $valid_principals,
    ttl: $ttl
  }' > "$REQUEST_FILE"

curl \
  --fail \
  --silent \
  --show-error \
  --request POST \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --header "Content-Type: application/json" \
  --data @"$REQUEST_FILE" \
  "${VAULT_ADDR}/v1/ssh-client-signer/sign/github-libvirt" \
  > "$RESPONSE_FILE"

jq -er '.data.signed_key' "$RESPONSE_FILE"