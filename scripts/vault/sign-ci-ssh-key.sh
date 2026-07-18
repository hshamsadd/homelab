#!/usr/bin/env bash
set -Eeuo pipefail

PUBLIC_KEY_FILE="${1:-}"
PRINCIPAL="${2:-}"
TTL="${3:-30m}"
SIGNING_ROLE="${4:-homelab-ci}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -n "$PUBLIC_KEY_FILE" ]] ||
  die "Public key file is required"

[[ -n "$PRINCIPAL" ]] ||
  die "SSH principal is required"

[[ -f "$PUBLIC_KEY_FILE" ]] ||
  die "Public key file not found: $PUBLIC_KEY_FILE"

: "${VAULT_ADDR:?VAULT_ADDR is required}"
: "${VAULT_TOKEN:?VAULT_TOKEN is required}"

for command_name in curl jq; do
  command -v "$command_name" >/dev/null 2>&1 ||
    die "Required command not found: $command_name"
done

PUBLIC_KEY="$(
  cat "$PUBLIC_KEY_FILE"
)"

REQUEST_BODY="$(
  jq \
    --null-input \
    --arg public_key "$PUBLIC_KEY" \
    --arg principal "$PRINCIPAL" \
    --arg ttl "$TTL" \
    '{
      public_key: $public_key,
      valid_principals: $principal,
      ttl: $ttl
    }'
)"

RESPONSE="$(
  curl \
    --silent \
    --show-error \
    --fail \
    --request POST \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --header "Content-Type: application/json" \
    --data-binary "$REQUEST_BODY" \
    "${VAULT_ADDR}/v1/ssh-client-signer/sign/${SIGNING_ROLE}"
)" || die "Vault SSH certificate signing failed"

SIGNED_KEY="$(
  jq -r '.data.signed_key // empty' <<< "$RESPONSE"
)"

[[ -n "$SIGNED_KEY" ]] ||
  die "Vault response did not contain a signed SSH certificate"

printf '%s\n' "$SIGNED_KEY"