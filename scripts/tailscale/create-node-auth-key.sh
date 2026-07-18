#!/usr/bin/env bash
set -Eeuo pipefail

DEVICE_TAG="${1:-}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

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

for command_name in curl jq; do
  command -v "$command_name" >/dev/null 2>&1 ||
    die "Required command not found: $command_name"
done

case "$DEVICE_TAG" in
  tag:k3s-worker)
    EPHEMERAL=true
    ;;
  *)
    EPHEMERAL=false
    ;;
esac

# One-time provisioning keys should have a short lifetime.
AUTH_KEY_EXPIRY_SECONDS="${TS_AUTH_KEY_EXPIRY_SECONDS:-900}"

TOKEN_RESPONSE="$(
  curl \
    --silent \
    --show-error \
    --fail \
    --request POST \
    --data-urlencode "client_id=${TS_API_CLIENT_ID}" \
    --data-urlencode "client_secret=${TS_API_CLIENT_SECRET}" \
    --data-urlencode "scope=auth_keys" \
    --data-urlencode "tags=${DEVICE_TAG}" \
    "https://api.tailscale.com/api/v2/oauth/token"
)" || die "Failed to obtain Tailscale API access token"

ACCESS_TOKEN="$(
  jq -r '.access_token // empty' <<< "$TOKEN_RESPONSE"
)"

[[ -n "$ACCESS_TOKEN" ]] ||
  die "Tailscale OAuth response did not contain an access token"

REQUEST_BODY="$(
  jq \
    --null-input \
    --arg tag "$DEVICE_TAG" \
    --argjson ephemeral "$EPHEMERAL" \
    --argjson expiry "$AUTH_KEY_EXPIRY_SECONDS" \
    '{
      capabilities: {
        devices: {
          create: {
            reusable: false,
            ephemeral: $ephemeral,
            preauthorized: true,
            tags: [$tag]
          }
        }
      },
      expirySeconds: $expiry,
      description: "homelab CI one-time provisioning key"
    }'
)"

KEY_RESPONSE="$(
  curl \
    --silent \
    --show-error \
    --fail \
    --request POST \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --header "Content-Type: application/json" \
    --data-binary "$REQUEST_BODY" \
    "https://api.tailscale.com/api/v2/tailnet/-/keys"
)" || die "Failed to create Tailscale auth key"

AUTH_KEY="$(
  jq -r '.key // empty' <<< "$KEY_RESPONSE"
)"

[[ -n "$AUTH_KEY" ]] ||
  die "Tailscale API response did not contain an auth key"

# IMPORTANT:
# The auth key is the only thing written to stdout.
# Callers can safely capture it with:
#
# TAILSCALE_AUTH_KEY="$(
#   scripts/tailscale/create-node-auth-key.sh tag:k3s-worker
# )
printf '%s\n' "$AUTH_KEY"


##########################################################
# #!/usr/bin/env bash
# set -euo pipefail

# DEVICE_TAG="${1:-}"

# case "$DEVICE_TAG" in
#   tag:infra-server|\
#   tag:k3s-control-plane|\
#   tag:k3s-worker|\
#   tag:app-server)
#     ;;
#   *)
#     echo "Unsupported Tailscale device tag: ${DEVICE_TAG}" >&2
#     echo "Allowed tags:" >&2
#     echo "  tag:infra-server" >&2
#     echo "  tag:k3s-control-plane" >&2
#     echo "  tag:k3s-worker" >&2
#     echo "  tag:app-server" >&2
#     exit 2
#     ;;
# esac

# : "${TS_API_CLIENT_ID:?TS_API_CLIENT_ID is required}"
# : "${TS_API_CLIENT_SECRET:?TS_API_CLIENT_SECRET is required}"

# if command -v tailscale-get-authkey >/dev/null 2>&1; then
#   GET_AUTHKEY_BIN="$(command -v tailscale-get-authkey)"
# elif command -v get-authkey >/dev/null 2>&1; then
#   GET_AUTHKEY_BIN="$(command -v get-authkey)"
# else
#   echo "tailscale-get-authkey is not installed or available in PATH." >&2
#   exit 1
# fi

# case "$DEVICE_TAG" in
#   tag:k3s-worker)
#     EPHEMERAL=true
#     ;;
#   *)
#     EPHEMERAL=false
#     ;;
# esac

# exec "$GET_AUTHKEY_BIN" \
#   -tags "$DEVICE_TAG" \
#   -preauth=true \
#   -reusable=false \
#   -ephemeral="$EPHEMERAL"

# exec "$GET_AUTHKEY_BIN" \
#   -tags "$DEVICE_TAG" \
#   -preauth=true \
#   -reusable=false \
#   -ephemeral=false