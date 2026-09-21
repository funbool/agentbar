<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · **🇨🇳 简体中文** · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

一款轻量的 macOS 菜单栏应用，显示你的 **Claude**、**Codex** 和 **Cursor** 额度已用多少，并提供 token 统计以及同等用量通过公开 API 的费用。

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## 功能

- **额度一目了然** — Claude 与 Codex 的 5 小时和每周窗口、Cursor 的套餐内用量池，每项都有进度条、距重置的剩余时间和确切重置日期。
- **按模型的每周额度**（Opus、Sonnet、Fable 等），API 一返回即显示。
- **使用统计** — 按类型的 token、费用、按模型与项目的细分、每日图表；今天 / 7 天 / 30 天 / 全部。
- **通知** — 额度超过阈值时提醒，支持全局默认值和按额度规则（静音、自定义阈值）。
- **可选自动刷新**、登录时启动、17 种界面语言。
- **通过 GitHub Releases 在线更新**，以 SHA-256 校验。
- **无需账号，无遥测。** AgentBar 读取官方客户端已存放在你 Mac 上的令牌，只与各提供商自己的 API 通信。

## 系统要求

- macOS 14 Sonoma 或更高（Apple 芯片或 Intel）。
- 至少一个已登录的客户端：[Claude Code](https://claude.com/claude-code)、[Codex](https://openai.com/codex)（CLI 或桌面应用）、[Cursor](https://cursor.com)。不使用的提供商可在设置中隐藏。

## 安装

1. 从[最新发布](https://github.com/funbool/agentbar/releases/latest)下载 `AgentBar.zip`。
2. 解压，将 `AgentBar.app` 移到 `/Applications`。
3. 打开应用。它会自动注册为登录项（可在设置中关闭）。

**Gatekeeper。** 发布版本为 ad hoc 签名，未经公证。若 macOS 拒绝打开刚下载的副本，请右键点击应用并选择一次 *打开*，或移除隔离标记：

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**钥匙串提示。** 首次刷新 Claude 时，macOS 会询问是否允许 `security` 读取 *Claude Code-credentials* 项。请选择 **始终允许**。Claude Code 轮换令牌后提示可能再次出现，这是正常现象。

你也可以[从源码构建](#从源码构建)。

## 工作原理

AgentBar 从不要求登录。它读取各客户端已保存在你 Mac 上的凭据，并调用与客户端相同的接口。

| 提供商 | 凭据来源 | 接口 | 显示内容 |
|---|---|---|---|
| Claude | 钥匙串项 `Claude Code-credentials`（通过 `/usr/bin/security` 读取） | `api.anthropic.com/api/oauth/usage` | 5 小时窗口、每周窗口、按模型的每周额度 |
| Codex | `~/.codex/auth.json`（或 `$CODEX_HOME/auth.json`） | `chatgpt.com/backend-api/wham/usage` | 5 小时窗口、每周窗口、套餐 |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`（只读打开） | `cursor.com/api/usage-summary`、`…/get-sand-usage-status` | Cursor 模型池（Auto / Composer / Grok）、API 模型池、按需消费、每周 Grok Bot、本周期已消费金额 |

AgentBar 不会刷新令牌。若某个提供商显示 *会话已过期*，打开该客户端一次即可，它会刷新令牌，AgentBar 在下次刷新时读取。

## 面板

- 点击菜单栏图标：所有提供商立即刷新；加载期间显示缓存值。
- 进度条低于 60 % 为绿色，高于为黄色，达到通知阈值后为红色。
- 每个额度显示剩余时间和确切重置时刻，例如 *2h 15m 后重置 · 周四 9月24日 20:00*。
- 额度旁的铃铛表示该额度的通知已开启（在设置中配置）。
- 底栏：统计 · 刷新 · 设置 · 退出。

## 使用统计

底栏的图表按钮打开统计窗口。顶部切换提供商和时间段；将鼠标悬停在图表上可查看当天总计或某个模型的份额。

| 提供商 | 数据来源 | 费用 |
|---|---|---|
| Claude | Claude Code 记录（`~/.claude/projects/**/*.jsonl`），索引一次并按文件缓存 | 同等用量通过 API 的费用：输入/输出按标价，缓存写入 ×1.25（5 分钟 TTL）/ ×2（1 小时 TTL），缓存读取 ×0.1 |
| Codex | 会话日志（`~/.codex/sessions/**/*.jsonl`） | OpenAI API 标价；缓存输入 ×0.1。无公开价格的模型仅显示 token |
| Cursor | Cursor 控制台的使用事件，本地缓存。首次打开时选择加载全部历史或仅当前计费周期；之后只获取新事件 | Cursor 对每个请求报告的金额 |

**为什么 AgentBar 的 Claude 总量与 Claude Code 的 `/stats` 不同。** Claude Code 按记录的每一行计数，而包含多个内容块（思考、文本、工具调用）的回复会被写成共享同一用量记录的多行，因此被重复计算。AgentBar 每条回复只计一次并取最终用量值——这才是 API 实际计费的数字——同时并列显示 Claude Code 的数字以供参考。

索引 700 MB 记录首次约需 10 秒，之后远少于 1 秒。缓存位于 `~/Library/Application Support/AgentBar/`。

## 通知

- 在设置 → 通知中开启通知并选择默认阈值（50–95 %）。
- 任意额度都可以在设置 → 通知中静音或设置单独阈值。
- 每个额度在每个重置周期只通知一次。
- 每次刷新时检查额度：开启自动刷新时按计划检查，否则仅在打开面板时检查。

## 设置

- **通用** — 自动刷新间隔（关闭 / 1 / 5 / 15 / 30 / 60 分钟）、显示的提供商、语言、登录时启动、更新。
- **通知** — 总开关、默认阈值、按额度规则。

## 更新

AgentBar 每天检查一次 GitHub Releases，也可在点击 *检查更新* 时检查。有新版本时面板会显示 *更新* 按钮。更新包下载后，会用发布的校验和验证 SHA-256，检查 bundle 标识符与版本，将旧应用移到废纸篓并启动新版本。你也可以在[发布页面](https://github.com/funbool/agentbar/releases)手动安装任意版本。

## 从源码构建

需要 Xcode 15 或更高（Swift 5.9）。无第三方依赖。

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # 单元测试
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # 构建、复制到 /Applications 并启动
```

调试工具（运行 bundle 内的二进制或 `.build/debug/AgentBar`）：

```bash
AgentBar --dump            # 获取每个提供商一次并打印解析后的额度
AgentBar --raw             # 打印每个接口的原始 JSON
AgentBar --stats           # 索引本地 Claude/Codex 日志并打印总计
AgentBar --cursor-events   # 获取 Cursor 使用事件并打印总计
AgentBar --update          # 无界面运行完整更新流程
```

### 发布

```bash
./scripts/release.sh 0.2.0
```

该脚本提升 `Packaging/Info.plist` 中的版本号，打上 `v0.2.0` 标签并推送。GitHub Actions 运行测试、构建应用、将 `AgentBar.zip` 和 `AgentBar.zip.sha256` 作为 release 发布，运行中的副本会在下次检查时获取。

## 隐私与安全

- **读取：** Claude Code 的钥匙串项、`~/.codex/auth.json`、Cursor 的 `state.vscdb`（只读）、本地记录和会话日志。
- **写入：** `~/Library/Application Support/AgentBar/` 下的偏好设置和缓存。
- **网络：** `api.anthropic.com`、`chatgpt.com`、`cursor.com`（你自己的使用数据）以及 `api.github.com` / `github.com`（检查和下载更新）。没有其他。
- 发布版本由 GitHub Actions 从打标签的源码构建；工作流位于 `.github/workflows/release.yml`。

## 故障排除

| 症状 | 处理方式 |
|---|---|
| *未登录 — 请打开 …* | 在该客户端登录一次；AgentBar 会在下次刷新时读取保存的令牌。 |
| 钥匙串提示反复出现 | 选择 *始终允许*。一段时间后再次出现说明 Claude Code 轮换了令牌。 |
| Cursor 没有显示 | 打开 Cursor 一次以刷新会话令牌，然后刷新 AgentBar。 |
| 下载后应用无法打开 | Gatekeeper — 见[安装](#安装)。 |
| 统计一直停在 *正在索引…* | 大型记录目录的首次索引需要一些时间；之后使用缓存。 |

## 致谢

接口调研参考了开源项目 [CodexBar](https://github.com/steipete/CodexBar)。

## 许可证

[MIT](../LICENSE)
