# AI Usage Limits

Lightweight macOS menu bar app showing the current usage limits of **Claude Code**, **Codex** and **Cursor**.
No login of its own: it reads the tokens the official clients already store on this Mac and calls the
same usage endpoints they do.

| Provider | Windows shown | Credentials source |
|---|---|---|
| Claude | 5-hour, weekly, per-model weekly limits (Opus / Sonnet / Fable …) when reported | Keychain item `Claude Code-credentials` |
| Codex | 5-hour, weekly | `~/.codex/auth.json` (or `$CODEX_HOME/auth.json`) |
| Cursor | Included pools as Cursor counts them: Cursor models (Auto / Composer / Grok) and third-party API models; on-demand; Grok Bot weekly; $ spent in the header | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` |

## Build & install

Requires Xcode 15+ command line tools (Swift 5.9, macOS 14+). No third-party dependencies.

```bash
./scripts/install.sh   # builds, copies to /Applications and launches
```

Or just build:

```bash
./scripts/build.sh     # -> build/AI Usage Limits.app
```

On the first fetch macOS asks whether `security` may read the Claude Code Keychain item — choose **Always Allow**.
The prompt can come back after Claude Code rotates its token; that's expected.

## Usage

- Click the gauge icon: every provider is refreshed immediately, progress bars turn yellow at 60 % and red at the
  notification threshold. Each row shows time until reset plus the exact reset date and time.
- ⚙︎ opens Settings: auto-refresh interval (off / 1 / 5 / 15 / 30 / 60 min), notifications with a threshold
  (50–95 %), provider visibility, language (system / English / Русский), launch at login.
- One notification per limit window per reset cycle.

## Usage statistics

The chart button next to each provider opens a statistics window (Today / 7 days / 30 days / All time):
tokens by type, cost, per-model and per-project breakdown, daily cost chart.

| Provider | Source | Cost |
|---|---|---|
| Claude | `~/.claude/projects/**/*.jsonl` transcripts, indexed once and cached per file in `~/Library/Application Support/AIUsageLimits/` | What the same usage would cost via the API: list prices, cache write ×1.25 (5 min) / ×2 (1 h), cache read ×0.1 |
| Codex | `~/.codex/sessions/**/*.jsonl` rollouts (`token_count` deltas) | OpenAI API list prices, cached input ×0.1; models without a public price show tokens only |
| Cursor | Dashboard usage events (`get-filtered-usage-events`), cached locally; first open asks whether to load all history or only the current billing cycle, later refreshes fetch only new events | As reported by Cursor per request |

## App icon

The icon source is `Packaging/AppIcon.svg`; `scripts/make-icon.sh` renders it into `Packaging/AppIcon.icns`
(all sizes 16–1024 incl. @2x), which `build.sh` copies into the bundle.

## Development

```bash
swift test                                # parsers, JWT, formatters, notification logic
swift build && .build/debug/AIUsageLimits --dump   # fetch all providers once and print the result
.build/debug/AIUsageLimits --raw                   # print raw JSON of every endpoint
.build/debug/AIUsageLimits --stats                 # index local Claude/Codex logs and print totals
.build/debug/AIUsageLimits --cursor-events         # fetch Cursor usage events and print totals
```

Tokens are never refreshed by this app; if a provider shows "session expired", open its client and it will refresh
the token on its own.
