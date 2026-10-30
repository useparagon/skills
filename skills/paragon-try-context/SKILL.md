---
name: paragon-try-context
description: Walk a developer through trying the Paragon Agent OS Context API from their terminal with curl. Covers getting a Project ID and signing key from the Paragon dashboard, storing the key safely, creating a Setup Link to connect a source, and running searches and passage reads. Use when someone wants to try, test, or demo Context API search; use paragon-implement-context to build it into an app.
---

# Try the Paragon Context API

Get the user from zero to a real search result in their own Paragon project, using `curl`. API calls need a signed JWT, so [scripts/paragon-env.sh](scripts/paragon-env.sh) mints one with `openssl` (no other dependencies) and loads `$PARAGON_TOKEN`, `$AGENTOS_URL`, `$ZEUS_URL`, and `$PARAGON_PROJECT_ID`. Shell state doesn't carry over between commands, so start every call with `source <this skill's dir>/scripts/paragon-env.sh &&`.

## Rules for secrets

- Never ask the user to paste a signing key, API key, or token into chat. Never `cat`, `echo`, or print the key file or `$PARAGON_TOKEN`.
- The key lives in `~/.paragon/signing-key.pem` (mode 600), outside any repository.
- The Setup Link URL is a credential for the test user. Show it only to the user who is trying this.

## 1. Collect settings from the dashboard

Ask the user for, or have them confirm:

1. **Project ID**: in the Paragon dashboard, click **Copy Project ID** under the environment switcher. It isn't secret.
2. **Region**: `us` (dashboard.useparagon.com) or `eu`. Defaults to `us`.
3. **Test user ID**: any stable ID for the Connected User, such as their email. This becomes the token `sub`.

Write them to `~/.paragon/agent-os.env`:

```sh
mkdir -p ~/.paragon && chmod 700 ~/.paragon
cat > ~/.paragon/agent-os.env <<'EOF'
PARAGON_PROJECT_ID=<uuid>
PARAGON_USER_ID=<id>
PARAGON_REGION=us
EOF
```

## 2. Store the signing key

If the user already keeps the project's signing key in a file, add `PARAGON_SIGNING_KEY_PATH=<path>` to the env file instead of copying the key.

Otherwise, have them open **Settings > SDK Setup** in the dashboard and generate a signing key. Warn them before they do: generating a new key invalidates the old one for that environment. If their app already uses a key, they should locate that one instead.

The dashboard downloads the key as a file. Move it into place, asking for the filename if you can't find the newest `.pem` in Downloads:

```sh
mv ~/Downloads/<downloaded-key>.pem ~/.paragon/signing-key.pem && chmod 600 ~/.paragon/signing-key.pem
```

If they copied the key to the clipboard instead, they can run `pbpaste > ~/.paragon/signing-key.pem && chmod 600 ~/.paragon/signing-key.pem` themselves on macOS.

Check the setup without exposing anything:

```sh
source scripts/paragon-env.sh && echo "ready: $AGENTOS_URL project $PARAGON_PROJECT_ID"
```

## 3. Connect a source

```sh
source scripts/paragon-env.sh && curl -sS -X POST "$ZEUS_URL/projects/$PARAGON_PROJECT_ID/setup-links" \
  -H "Authorization: Bearer $PARAGON_TOKEN" -H "Content-Type: application/json" \
  -d '{"expiresIn": 3600, "integrations": ["googledrive"]}'
```

Leave out `integrations` to offer every integration enabled for the project. Give the user the returned `url`. On that hosted page they connect an app (Google Drive, Box, SharePoint, OneDrive, Dropbox, or Confluence) and choose folders or files to sync. Error `56016` means Setup Links aren't enabled for the project, and `56004` means that integration isn't enabled. For either one, point the user to their Paragon dashboard or their Paragon contact.

Indexing takes a while after the user picks content. The Setup Link page shows sync status. Wait until the content shows as searchable.

## 4. Search and read

```sh
source scripts/paragon-env.sh && curl -sS -X POST "$AGENTOS_URL/api/context/projects/$PARAGON_PROJECT_ID/search" \
  -H "Authorization: Bearer $PARAGON_TOKEN" -H "Content-Type: application/json" \
  -d '{"query": "q2 roadmap", "topK": 5}'
```

- Search runs as the Connected User in the token. Leave out the optional `identity` field. Other optional fields: `sources` (e.g. `["googledrive"]`), `topK` (1–50), and `segmentsPerRecord` (passages per result, 1–5).
- Each result has `segments[].pointer`. Read the text around one with:

```sh
source scripts/paragon-env.sh && curl -sS -G "$AGENTOS_URL/api/context/projects/$PARAGON_PROJECT_ID/segments/<pointer>/context" \
  -H "Authorization: Bearer $PARAGON_TOKEN" -d direction=around -d maxTokens=2000
```

URL-encode the pointer if it contains characters other than letters, digits, `.`, `-`, and `_`. To keep reading, pass the response's `next` with `direction=after` or its `prev` with `direction=before`.

Summarize the results for the user: which records matched, their best passages, and anything in `usage` that explains a thin result (`underfilled`, `degraded`, or a `retrievalMode` other than `hybrid`).

## When it doesn't work

- **No results:** content may still be indexing, the test user ID may not match the user who connected the source, or `sources` may be too narrow. Empty results don't prove the content is missing.
- **401/403:** check for the wrong region, a Project ID from a different environment than the key, or a key that was regenerated.
- **404 on read:** the pointer is stale or access was denied, and the API returns the same error for both. Search again to get a fresh pointer.

API reference: https://docs.useparagon.com/agent-os/context/overview.md. OpenAPI spec: https://docs.useparagon.com/agent-os/openapi/context.json. When the user is ready to build this into their app, use the `paragon-implement-context` skill.
