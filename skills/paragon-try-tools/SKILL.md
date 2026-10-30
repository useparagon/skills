---
name: paragon-try-tools
description: Walk a developer through trying the Paragon Agent OS Tools API from their terminal with curl. Covers getting a Project ID and signing key from the Paragon dashboard, storing the key safely, connecting an app, searching for tools, running one, and reading its results. Use when someone wants to try, test, or demo Tools API search and execution; use paragon-implement-tools to build it into an app.
---

# Try the Paragon Tools API

Get the user from zero to a real tool run in their own Paragon project, using `curl`. API calls need a signed JWT, so [scripts/paragon-env.sh](scripts/paragon-env.sh) mints one with `openssl` (no other dependencies) and loads `$PARAGON_TOKEN`, `$AGENTOS_URL`, `$ZEUS_URL`, and `$PARAGON_PROJECT_ID`. Shell state doesn't carry over between commands, so start every call with `source <this skill's dir>/scripts/paragon-env.sh &&`. Below, `$T` stands for `$AGENTOS_URL/api/tools/projects/$PARAGON_PROJECT_ID`. Define it inline: `T="$AGENTOS_URL/api/tools/projects/$PARAGON_PROJECT_ID"`.

## Rules for secrets and actions

- Never ask the user to paste a signing key, API key, or token into chat. Never `cat`, `echo`, or print the key file or `$PARAGON_TOKEN`.
- The key lives in `~/.paragon/signing-key.pem` (mode 600), outside any repository.
- Tools act on the user's real accounts. Run `read` tools freely. Before running any tool whose `sideEffect` is `write`, `delete`, `send`, or `unknown`, show the user the tool and its exact args and wait for a yes.

## 1. Collect settings from the dashboard

Ask the user for, or have them confirm:

1. **Project ID**: in the Paragon dashboard, click **Copy Project ID** under the environment switcher. It isn't secret.
2. **Region**: `us` (dashboard.useparagon.com) or `eu`. Defaults to `us`.
3. **Test user ID**: the Connected User to act as. To use apps the user already connected through their own product, use that user's existing Paragon user ID. Otherwise pick any stable ID, such as their email. This becomes the token `sub`.

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

## 3. Find tools

```sh
source scripts/paragon-env.sh && T="$AGENTOS_URL/api/tools/projects/$PARAGON_PROJECT_ID" && \
curl -sS -X POST "$T/tools/search" -H "Authorization: Bearer $PARAGON_TOKEN" -H "Content-Type: application/json" \
  -d '{"query": "list open issues", "connectedOnly": true, "maxSideEffect": "read", "topK": 5}'
```

Each tool in `tools[]` has an `intentName`, `integration`, `sideEffect`, `approvalRequired`, and a JSON Schema at `tool.function.parameters`. Drop `maxSideEffect` when the user wants to write or send something. Add `"integrations": ["jira"]` to narrow by app. To see one tool's full schema, use `curl -sS "$T/tools/<intentName>" -H "Authorization: Bearer $PARAGON_TOKEN"`.

If no tools come back, the app probably isn't connected for this user ID. Check `errors` and `usage` for omitted counts, then search with `"connectedOnly": false` to see which integrations have matching tools. To connect one, create a hosted link and give the user its `url`:

```sh
source scripts/paragon-env.sh && curl -sS -X POST "$ZEUS_URL/projects/$PARAGON_PROJECT_ID/setup-links" \
  -H "Authorization: Bearer $PARAGON_TOKEN" -H "Content-Type: application/json" -d '{"integrations": ["jira"]}'
```

The integration has to be enabled in the project. If Setup Links aren't enabled (`56016`), the user can connect the app for the same user ID through their own product's Connect Portal.

## 4. Run a tool

Build `args` from the tool's schema, not from its name, and ask the user for any values you can't infer.

```sh
source scripts/paragon-env.sh && T="$AGENTOS_URL/api/tools/projects/$PARAGON_PROJECT_ID" && \
curl -sS -X POST "$T/executions" -H "Authorization: Bearer $PARAGON_TOKEN" -H "Content-Type: application/json" \
  -H "Prefer: wait=25" -d '{"intentName": "<intentName>", "args": {}, "outputMode": "auto"}'
```

- If `status` is `running`, poll the same execution until it reaches `completed`, `failed`, `timeout`, or `cancelled`: `curl -sS "$T/executions/<executionId>" -H "Authorization: Bearer $PARAGON_TOKEN" -H "Prefer: wait=25"`. Never re-send the POST to check status, because that runs the tool again.
- Small output comes back in `output.inline`. Large output is stored, and the response includes `output.resultId` instead. Stored results are kept for 24 hours.
- On failure, inspect `calls[]` for the upstream status and error.

## 5. Read large results

Read only what the task needs:

```sh
source scripts/paragon-env.sh && T="$AGENTOS_URL/api/tools/projects/$PARAGON_PROJECT_ID" && \
curl -sS -G "$T/results/<resultId>/rows" -H "Authorization: Bearer $PARAGON_TOKEN" \
  -d select=id,title --data-urlencode "where=status:eq:open" -d pageSize=20
```

- `GET $T/results/<resultId>` returns a summary with the result's `shape`, a record count, and a `sample` of at most three records. The sample is not the full result.
- For records, pass the response's `paging.continuationToken` back as `continuationToken` to get the next page. `where` can repeat, using `eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `contains`, or `exists`.
- For text, use `$T/results/<resultId>/content?startChar=0&maxChars=5000` and continue from `nextStartChar`.

Report the outcome plainly: the final status, what the tool returned, and whether you read all of a stored result or only part of it.

## When it doesn't work

- **401/403:** check for the wrong region, a Project ID from a different environment than the key, or a key that was regenerated.
- **No tools found:** the app isn't connected for this user ID, `maxSideEffect` filtered the tools out, or the query is too specific.

API reference: https://docs.useparagon.com/agent-os/tools/overview.md. OpenAPI spec: https://docs.useparagon.com/agent-os/openapi/tools.json. When the user is ready to build this into their app, use the `paragon-implement-tools` skill.
