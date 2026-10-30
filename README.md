# Paragon skills

Agent skills for Paragon Agent OS. Each folder under `skills/` can be installed on its own with the [skills CLI](https://github.com/vercel-labs/skills).

| Skill | Purpose |
| --- | --- |
| [paragon-try-context](skills/paragon-try-context/SKILL.md) | Set up credentials and try Context API search from the terminal with curl. |
| [paragon-try-tools](skills/paragon-try-tools/SKILL.md) | Set up credentials and try Tools API search and execution from the terminal with curl. |
| [paragon-implement-context](skills/paragon-implement-context/SKILL.md) | Add Setup Link onboarding and permission-aware search to an app. |
| [paragon-implement-tools](skills/paragon-implement-tools/SKILL.md) | Add tool discovery, execution, and result paging to an app's agent. |

The try skills need only `curl` and `openssl`. They keep the signing key in `~/.paragon/signing-key.pem` and never print it or the tokens they mint. The implement skills work in the app's own stack and reuse its existing Paragon JWT signing.

All four skills point to the public docs and OpenAPI specs at https://docs.useparagon.com/agent-os/overview rather than bundling copies.

## Install

Run from the project where you want to use the skills:

```sh
npx skills add useparagon/skills --list
npx skills add useparagon/skills --skill '*'
```

Choose one skill with `--skill paragon-try-tools` (for example). Use `--agent claude-code` or `--agent codex` to pick an agent, or `--global` for a user-wide install.

## OpenAI plugin package

The root `plugin.json` packages these skills as **Paragon Agent OS** in the Agent Plugins 1.0 format. Each skill includes `agents/openai.yaml` for display metadata and its own copy of the logo, so a single-skill install stays self-contained. To build an upload ZIP:

```sh
zip -r /tmp/paragon-agent-os.zip plugin.json assets skills -x '*/.DS_Store'
```
