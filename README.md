<!-- LANGS -->
**🇬🇧 English** · [🇷🇺 Русский](docs/README.ru.md) · [🇺🇦 Українська](docs/README.uk.md) · [🇩🇪 Deutsch](docs/README.de.md) · [🇫🇷 Français](docs/README.fr.md) · [🇪🇸 Español](docs/README.es.md) · [🇵🇹 Português](docs/README.pt-PT.md) · [🇧🇷 Português (Brasil)](docs/README.pt-BR.md) · [🇵🇱 Polski](docs/README.pl.md) · [🇨🇿 Čeština](docs/README.cs.md) · [🇭🇺 Magyar](docs/README.hu.md) · [🇹🇷 Türkçe](docs/README.tr.md) · [🇰🇿 Қазақша](docs/README.kk.md) · [🇮🇳 हिन्दी](docs/README.hi.md) · [🇯🇵 日本語](docs/README.ja.md) · [🇨🇳 简体中文](docs/README.zh-Hans.md) · [🇹🇼 繁體中文](docs/README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

A lightweight macOS menu bar app that shows how much of your **Claude**, **Codex** and **Cursor** limits you have used — plus token statistics and what the same usage would cost through the public APIs.

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## Features

- **Limits at a glance** — 5-hour and weekly windows for Claude and Codex, included usage pools for Cursor, each with a progress bar, the time left until reset and the exact reset date.
- **Per-model weekly limits** for Claude (Opus, Sonnet, Fable, …) as soon as the API reports them.
- **Usage statistics** — tokens by type, cost, per-model and per-project breakdown, daily chart; Today / 7 days / 30 days / All time.
- **Notifications** when a limit passes a threshold, with a global default and per-limit overrides (mute, custom threshold).
- **Optional auto-refresh**, launch at login, 17 interface languages.
- **Over-the-air updates** from GitHub Releases, verified with SHA-256.
- **No accounts, no telemetry.** AgentBar reads the tokens the official clients already store on your Mac and talks only to the providers' own APIs.

## Requirements

- macOS 14 Sonoma or later (Apple silicon or Intel).
- At least one of: [Claude Code](https://claude.com/claude-code), [Codex](https://openai.com/codex) (CLI or desktop app), [Cursor](https://cursor.com) — signed in. Providers you do not use can be hidden in Settings.

## Installation

1. Download `AgentBar.zip` from the [latest release](https://github.com/funbool/agentbar/releases/latest).
2. Unzip it and move `AgentBar.app` to `/Applications`.
3. Open the app. It registers itself as a login item (you can turn that off in Settings).

**Gatekeeper.** Releases are signed ad hoc, not notarized. If macOS refuses to open a freshly downloaded copy, right-click the app and choose *Open* once, or remove the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**Keychain prompt.** On the first Claude refresh macOS asks whether `security` may read the *Claude Code-credentials* item. Choose **Always Allow**. The prompt can come back after Claude Code rotates its token — that is expected.

You can also [build from source](#build-from-source).

## How it works

AgentBar never asks you to sign in. It reads the credentials each client already keeps on your Mac and calls the same endpoints the clients use.

| Provider | Credentials read from | Endpoint | What is shown |
|---|---|---|---|
| Claude | Keychain item `Claude Code-credentials` (read through `/usr/bin/security`) | `api.anthropic.com/api/oauth/usage` | 5-hour window, weekly window, per-model weekly limits |
| Codex | `~/.codex/auth.json` (or `$CODEX_HOME/auth.json`) | `chatgpt.com/backend-api/wham/usage` | 5-hour window, weekly window, plan |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` (opened read-only) | `cursor.com/api/usage-summary`, `…/get-sand-usage-status` | Cursor-models pool (Auto / Composer / Grok), API-models pool, on-demand spend, Grok Bot weekly, money spent this cycle |

AgentBar does not refresh tokens itself. If a provider shows *session expired*, open that client once — it will refresh the token and AgentBar picks it up on the next refresh.

## The panel

- Click the menu bar icon: every provider is refreshed immediately; cached values are shown while loading.
- Bars are green below 60 %, yellow above, red once the notification threshold is reached.
- Each limit shows the time left and the exact reset moment, e.g. *resets in 2h 15m · Thu 24 Sep 20:00*.
- A bell next to a limit means notifications are on for it (configured in Settings).
- Footer: statistics · refresh · settings · quit.

## Usage statistics

The chart button in the panel footer opens the statistics window. Switch between providers and periods at the top; hover the chart to see a day's totals or a single model's share.

| Provider | Source | Cost |
|---|---|---|
| Claude | Claude Code transcripts (`~/.claude/projects/**/*.jsonl`), indexed once and cached per file | What the same usage would cost through the API: input/output at list price, cache writes ×1.25 (5-minute TTL) / ×2 (1-hour TTL), cache reads ×0.1 |
| Codex | Session rollouts (`~/.codex/sessions/**/*.jsonl`) | OpenAI API list prices; cached input ×0.1. Models without a public price show tokens only |
| Cursor | Usage events from the Cursor dashboard, cached locally. On first open you choose whether to load the whole history or only the current billing cycle; later refreshes fetch only new events | As reported by Cursor for each request |

**Why AgentBar's Claude totals differ from `/stats` in Claude Code.** Claude Code counts every transcript line, and a reply with several content blocks (thinking, text, tool calls) is written as several lines sharing one usage record, so multi-block replies are counted several times. AgentBar counts each reply once, taking the final usage values — the figure the API actually bills — and shows the Claude Code number next to it for reference.

Indexing 700 MB of transcripts takes about 10 seconds the first time and well under a second afterwards. Caches live in `~/Library/Application Support/AgentBar/`.

## Notifications

- Turn notifications on in Settings → Notifications and pick a default threshold (50–95 %).
- Every limit can be muted or given its own threshold in Settings → Notifications.
- You get one notification per limit per reset cycle.
- Limits are checked whenever the app refreshes: on a schedule if auto-refresh is on, otherwise only when you open the panel.

## Settings

- **General** — auto-refresh interval (off / 1 / 5 / 15 / 30 / 60 min), visible providers, language, launch at login, updates.
- **Notifications** — global switch, default threshold, per-limit rules.

## Updates

AgentBar checks GitHub Releases once a day and whenever you press *Check for updates*. When a newer version exists the panel shows an *Update* button. The update is downloaded, its SHA-256 is verified against the published checksum, the bundle identifier and version are checked, the old app is moved to the Trash and the new one is launched. You can also install any release by hand from the [releases page](https://github.com/funbool/agentbar/releases).

## Build from source

Requires Xcode 15 or later (Swift 5.9). No third-party dependencies.

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # unit tests
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # build, copy to /Applications and launch
```

Debug helpers (run the binary inside the bundle or `.build/debug/AgentBar`):

```bash
AgentBar --dump            # fetch every provider once and print the parsed limits
AgentBar --raw             # print the raw JSON of every endpoint
AgentBar --stats           # index local Claude/Codex logs and print totals
AgentBar --cursor-events   # fetch Cursor usage events and print totals
AgentBar --update          # run the full update cycle headlessly
```

### Releasing

```bash
./scripts/release.sh 0.2.0
```

This bumps the version in `Packaging/Info.plist`, tags `v0.2.0` and pushes. GitHub Actions runs the tests, builds the app, publishes `AgentBar.zip` and `AgentBar.zip.sha256` as a release, and running copies pick it up on their next check.

## Privacy and security

- **Reads:** the Claude Code Keychain item, `~/.codex/auth.json`, Cursor's `state.vscdb` (read-only), local transcripts and session logs.
- **Writes:** preferences and caches under `~/Library/Application Support/AgentBar/`.
- **Network:** `api.anthropic.com`, `chatgpt.com`, `cursor.com` (your own usage data) and `api.github.com` / `github.com` (update checks and downloads). Nothing else.
- Releases are built by GitHub Actions from the tagged source; the workflow is in `.github/workflows/release.yml`.

## Troubleshooting

| Symptom | What to do |
|---|---|
| *Not signed in — open …* | Sign in to that client once; AgentBar reads the stored token on the next refresh. |
| Keychain prompt keeps appearing | Choose *Always Allow*. A new prompt after some time means Claude Code rotated its token. |
| Cursor shows nothing | Open Cursor once so it refreshes its session token, then refresh AgentBar. |
| App does not open after download | Gatekeeper — see [Installation](#installation). |
| Statistics look stuck at *Indexing…* | The first index of large transcript folders can take a while; later runs use the cache. |

## Acknowledgements

Endpoint research was helped by the open-source [CodexBar](https://github.com/steipete/CodexBar) project.

## License

[MIT](LICENSE)
