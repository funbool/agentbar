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

## Development

```bash
swift test                                # parsers, JWT, formatters, notification logic
swift build && .build/debug/AIUsageLimits --dump   # fetch all providers once and print the result
.build/debug/AIUsageLimits --raw                   # print raw JSON of every endpoint
```

Tokens are never refreshed by this app; if a provider shows "session expired", open its client and it will refresh
the token on its own.
