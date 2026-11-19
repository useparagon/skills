# Skills for Paragon Agent OS

| Skill | Purpose |
| --- | --- |
| [paragon-start-here](skills/paragon-start-here/SKILL.md) | Answer a few questions about what you're building and get a recommended next step. |
| [paragon-try-context](skills/paragon-try-context/SKILL.md) | Set up credentials and try Context API search from the terminal with curl. |
| [paragon-try-tools](skills/paragon-try-tools/SKILL.md) | Set up credentials and try Tools API search and execution from the terminal with curl. |
| [paragon-implement-context](skills/paragon-implement-context/SKILL.md) | Add Setup Link onboarding and permission-aware search to an app. |
| [paragon-implement-tools](skills/paragon-implement-tools/SKILL.md) | Add tool discovery, execution, and result paging to an app's agent. |

The try skills work best with the Paragon MCP connected (see below), which replaces the signing-key setup. Without it they need only `curl` and `openssl`, keep the signing key in `~/.paragon/signing-key.pem`, and never print it or the tokens they mint. The implement skills work in the app's own stack and reuse its existing Paragon JWT signing.

Learn more at https://docs.useparagon.com/agent-os/overview

## Install

Run from the project where you want to use the skills:

```sh
npx skills add useparagon/skills --list
npx skills add useparagon/skills --skill '*'
```

Choose one skill with `--skill paragon-try-tools` (for example). Use `--agent claude-code` or `--agent codex` to pick an agent, or `--global` for a user-wide install.

## Connect the Paragon MCP

The Paragon Developer MCP is hosted at `https://developer-mcp.useparagon.com/mcp`. You sign in through the Paragon dashboard in your browser, so there is no token or key to paste into the config. Once connected, the try skills use it to find your project, add integrations, create Setup Links, and mint short-lived test tokens. Integration tools and test tokens work on Development projects.

Cursor (`.cursor/mcp.json`, or `~/.cursor/mcp.json` for all projects). Cursor doesn't support dynamic client discovery yet, so the config must include Paragon's pre-registered client ID, `paragon-cursor`:

```json
{
  "mcpServers": {
    "paragon": {
      "url": "https://developer-mcp.useparagon.com/mcp",
      "auth": {
        "CLIENT_ID": "paragon-cursor"
      }
    }
  }
}
```

Claude Code:

```sh
claude mcp add --transport http paragon https://developer-mcp.useparagon.com/mcp
```

Codex/ChatGPT and GitHub Copilot: add it as a remote HTTP MCP server with the same URL.

The MCP currently works with only Cursor, Claude Code, Codex/ChatGPT, and GitHub Copilot. On any other client, the try skills use the signing-key setup instead.

Then ask your agent to try the Tools API or Context API and approve access when the browser opens.
