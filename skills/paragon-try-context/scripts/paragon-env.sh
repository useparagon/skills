# Source this file to set PARAGON_TOKEN, AGENTOS_URL, ZEUS_URL, and PARAGON_PROJECT_ID
# for curl. Needs only bash/zsh and openssl. Never prints the signing key or the token.
#
#   source scripts/paragon-env.sh && curl -H "Authorization: Bearer $PARAGON_TOKEN" ...
#
# Settings come from ~/.paragon/agent-os.env (non-secret):
#   PARAGON_PROJECT_ID=<uuid>  PARAGON_USER_ID=<id>  PARAGON_REGION=us|eu
#   PARAGON_SIGNING_KEY_PATH=~/.paragon/signing-key.pem   (optional)
#   PARAGON_AGENTOS_URL, PARAGON_ZEUS_URL                 (optional host overrides)

_paragon_env() {
  local config="$HOME/.paragon/agent-os.env"
  [ -f "$config" ] && . "$config"
  local key="${PARAGON_SIGNING_KEY_PATH:-$HOME/.paragon/signing-key.pem}"
  key="${key/#\~/$HOME}"

  [ -n "$PARAGON_PROJECT_ID" ] || { echo "PARAGON_PROJECT_ID is not set in $config" >&2; return 1; }
  [ -n "$PARAGON_USER_ID" ] || { echo "PARAGON_USER_ID is not set in $config" >&2; return 1; }
  [ -f "$key" ] || { echo "No signing key at $key. Save the key from Settings > SDK Setup there first." >&2; return 1; }
  grep -q "PRIVATE KEY" "$key" || { echo "$key does not look like a PEM private key." >&2; return 1; }
  local mode
  mode=$(stat -f %Lp "$key" 2>/dev/null || stat -c %a "$key" 2>/dev/null)
  case "$mode" in 600|400) ;; *) echo "Warning: $key is readable by other users. Run: chmod 600 \"$key\"" >&2 ;; esac

  case "${PARAGON_REGION:-us}" in
    us) AGENTOS_URL=https://agentos.useparagon.com; ZEUS_URL=https://zeus.useparagon.com ;;
    eu) AGENTOS_URL=https://agentos.eu.paragon.so; ZEUS_URL=https://zeus.eu.paragon.so ;;
    *) echo "PARAGON_REGION must be us or eu" >&2; return 1 ;;
  esac
  AGENTOS_URL="${PARAGON_AGENTOS_URL:-$AGENTOS_URL}"
  ZEUS_URL="${PARAGON_ZEUS_URL:-$ZEUS_URL}"

  local b64url='openssl base64 -A | tr "+/" "-_" | tr -d "="'
  local now header payload signature
  now=$(date +%s)
  header=$(printf '{"alg":"RS256","typ":"JWT"}' | eval "$b64url")
  payload=$(printf '{"sub":"%s","aud":"useparagon.com/%s","iat":%s,"exp":%s}' \
    "$PARAGON_USER_ID" "$PARAGON_PROJECT_ID" "$now" "$((now + 3600))" | eval "$b64url")
  signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign "$key" -binary | eval "$b64url") \
    || { echo "Signing failed. Check the key file." >&2; return 1; }
  [ -n "$signature" ] || { echo "Signing failed. Check the key file." >&2; return 1; }
  PARAGON_TOKEN="$header.$payload.$signature"
  export PARAGON_TOKEN AGENTOS_URL ZEUS_URL PARAGON_PROJECT_ID
}

_paragon_env
