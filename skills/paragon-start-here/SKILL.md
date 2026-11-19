---
name: paragon-start-here
description: Intake and triage for people new to Paragon Agent OS. Asks a few short questions about what they're building (Context, Tools, or both), which apps and users are involved, and where they are in the process, then recommends actionable next steps and points them to the right docs pages. Use when someone asks what Agent OS is, whether it fits their use case, where to start, or wants to learn more; next steps include paragon-try-context, paragon-try-tools, paragon-implement-context, and paragon-implement-tools.
---

# Start here with Paragon Agent OS

Work out what the user needs and send them to the right next step. Keep it a conversation, not a form.

## Ground rules

- Ask one or two questions at a time, in plain language. Skip anything you can already answer from the conversation or the repo (see "Look first").
- Offer likely answers so the user can reply with a word. Accept "not sure" and move on.
- Never ask for a signing key, API key, or token. Later skills handle credentials safely.
- Be accurate about what exists. Agent OS has two APIs, Context and Tools, plus a Developer MCP that helps set up a project from a coding agent. When unsure, say so and point to the docs or the Paragon team.
- Don't send the user's answers anywhere.

Docs: https://docs.useparagon.com/agent-os/overview

## What Agent OS is

Paragon's integration layer for AI agents, so an agent can work across the SaaS apps your users already use.

- **Context API:** the agent searches and reads content from each user's connected knowledge sources. Users connect sources through a hosted Setup Link, and search results only include what that user can access in the source app. Supported sources today: Google Drive, OneDrive, SharePoint, Dropbox, Box, Confluence. Docs: https://docs.useparagon.com/agent-os/context/overview.md
- **Tools API:** the agent searches a library of pre-built actions, runs them as the connected user, and pages through large results. Docs: https://docs.useparagon.com/agent-os/tools/overview.md

Both identify the end user with a Paragon User Token that the customer's backend signs.

## Look first

If you're inside a codebase, check for existing Paragon usage before asking:

```sh
rg -n -i "paragon|useparagon\.com|PARAGON_" --glob '!**/node_modules/**' | head -20
```

Don't print secret values or `.env` contents. Existing Paragon code usually means they already have a project and a token signer, which shortens the path.

## Intake

Ask these roughly in order. Stop once you can recommend a next step.

1. **Goal.** "What should your agent be able to do for your users?" Listen for:
   - Answer questions from their documents or knowledge (Context).
   - Do things in their apps, like create a ticket, send a message, or update a record (Tools).
   - Both. Start with whichever matters more for the first use case.
2. **Apps.** "Which apps matter most?" Check them against the Context sources above. For Tools, ask which actions they need. If an app isn't in the docs, say you can't confirm support and suggest raising it with the Paragon team.
3. **Whose accounts and permissions.** "Does each of your users connect their own accounts, and should the agent only see what that user can see?" That's the model both APIs are built for: Context applies the user's permissions, and Tools always run as the connected user. A single shared or admin account is a different setup, so flag it for a conversation with the Paragon team.
4. **Stage.** "Are you exploring, prototyping, adding this to an existing app, or already building for production?"
5. **Paragon today.** "Do you already have a Paragon account or project? Does your app use the Connect SDK or ActionKit?" No account means they'll need to sign up at https://dashboard.useparagon.com/signup?product=agentos.
6. **Stack and agent.** "What language and framework is your backend, and what agent framework or host does your agent run in?" This matters for implementing and for whether the MCP quick start applies.
7. **Region and constraints.** "Do you need the EU region, or have data residency, security review, or self-hosting requirements?" Agent OS has US and EU endpoints. If they have self-hosting requirements, point them to https://www.useparagon.com/request-a-demo to get in touch with the Paragon sales team, and don't speculate about what self-hosting supports. Treat compliance questions as ones for the Paragon team to answer too.
8. **Scale and timing (optional).** "Roughly how many end users and how much content, and when do you want to launch?" Ask only if the conversation is heading toward production.
9. **Who.** If it helps the handoff, ask their role (engineer, product, other) and whether they're evaluating for their own company or a customer.

## Recommend a next step

Use what you heard to say, in a few sentences, whether Agent OS looks like a fit and what to do next:

- **Clear fit:** an agent or AI feature that acts on behalf of end users across their own connected apps, using Context sources or Tools actions the docs cover. Point to a self-serve next step.
- **Fit with questions:** an unsupported or unlisted app, EU, self-hosting, or compliance needs, shared accounts, very large content volumes, or a tight launch date. Suggest trying it, and name the open questions to raise with the Paragon team.
- **Probably not a fit yet:** needs unrelated to connecting users' apps to an agent. Say so plainly and don't force a recommendation.

| Situation | Next step |
| --- | --- |
| Wants to see it work, no existing integration | Offer `paragon-try-context` (search their content) or `paragon-try-tools` (find and run a tool). Both start by connecting the Paragon MCP when the host supports it. |
| Has an app and is ready to build | Offer `paragon-implement-context` or `paragon-implement-tools`. Suggest a quick try first if they haven't seen the API respond. |
| Needs both Context and Tools | Start with the one tied to their first use case, then do the other. |
| No Paragon account yet | Send them to https://dashboard.useparagon.com/signup?product=agentos, then continue. |
| Self-hosting, compliance, or other questions only the Paragon team can answer | https://www.useparagon.com/request-a-demo |

Offer to start the matching skill, and wait for a yes before running it.

## Educate with the docs

Teach as you go. Explain the one or two ideas that matter for their use case, then point to the specific docs pages that cover them instead of pasting long explanations. Say why each page is worth opening.

| If they care about | Point them to |
| --- | --- |
| The big picture, regions, and auth | https://docs.useparagon.com/agent-os/overview.md |
| How users connect sources, and how search works | https://docs.useparagon.com/agent-os/context/overview.md and https://docs.useparagon.com/agent-os/context/create-setup-link.md |
| Searching content and reading passages | https://docs.useparagon.com/agent-os/context/search.md and https://docs.useparagon.com/agent-os/context/read-segment.md |
| Finding and running tools, and large results | https://docs.useparagon.com/agent-os/tools/overview.md, https://docs.useparagon.com/agent-os/tools/search.md, and https://docs.useparagon.com/agent-os/tools/create-execution.md |
| Syncing content and permissions behind Context | https://docs.useparagon.com/managed-sync/overview.md and https://docs.useparagon.com/managed-sync/permissions-api.md |

For anything not in the table, search the docs instead of guessing:

- Read https://docs.useparagon.com/llms.txt for the full page index and match page titles to the question.
- Or, if the Paragon docs MCP (`https://docs.useparagon.com/mcp`, no sign-in needed) is available, search it for the user's exact question.
- Every docs page is also available as Markdown by adding `.md` to its URL, which is easier to read and quote.

Answer from what you find, link the page, and say when the docs don't cover something.
