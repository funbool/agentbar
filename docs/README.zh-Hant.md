<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · [🇯🇵 日本語](README.ja.md) · [🇨🇳 简体中文](README.zh-Hans.md) · **🇹🇼 繁體中文**
<!-- /LANGS -->

# AgentBar

一款輕量的 macOS 選單列應用程式，顯示你的 **Claude**、**Codex** 與 **Cursor** 額度已使用多少，並提供 token 統計以及同等用量透過公開 API 的費用。

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## 功能

- **額度一目瞭然** — Claude 與 Codex 的 5 小時和每週視窗、Cursor 的方案內用量池，每項都有進度條、距重設的剩餘時間與確切重設日期。
- **依模型的每週額度**（Opus、Sonnet、Fable 等），API 一回報即顯示。
- **使用統計** — 依類型的 token、費用、依模型與專案的細分、每日圖表；今天 / 7 天 / 30 天 / 全部。
- **通知** — 額度超過門檻時提醒，支援全域預設值與各額度規則（靜音、自訂門檻）。
- **可選的自動重新整理**、登入時啟動、17 種介面語言。
- **透過 GitHub Releases 線上更新**，以 SHA-256 驗證。
- **不需帳號，無遙測。** AgentBar 讀取官方用戶端已儲存在你 Mac 上的權杖，只與各供應商自己的 API 通訊。

## 系統需求

- macOS 14 Sonoma 或更新版本（Apple 晶片或 Intel）。
- 至少一個已登入的用戶端：[Claude Code](https://claude.com/claude-code)、[Codex](https://openai.com/codex)（CLI 或桌面應用程式）、[Cursor](https://cursor.com)。不使用的供應商可在設定中隱藏。

## 安裝

1. 從[最新版本](https://github.com/funbool/agentbar/releases/latest)下載 `AgentBar.zip`。
2. 解壓縮，將 `AgentBar.app` 移至 `/Applications`。
3. 開啟應用程式。它會自動註冊為登入項目（可在設定中關閉）。

**Gatekeeper。** 發行版本為 ad hoc 簽署，未經公證。若 macOS 拒絕開啟剛下載的副本，請在應用程式上按右鍵並選擇一次 *打開*，或移除隔離旗標：

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**鑰匙圈提示。** 首次重新整理 Claude 時，macOS 會詢問是否允許 `security` 讀取 *Claude Code-credentials* 項目。請選擇 **永遠允許**。Claude Code 輪換權杖後提示可能再次出現，這是正常現象。

你也可以[從原始碼建置](#從原始碼建置)。

## 運作方式

AgentBar 從不要求登入。它讀取各用戶端已保存在你 Mac 上的憑證，並呼叫與用戶端相同的端點。

| 供應商 | 憑證來源 | 端點 | 顯示內容 |
|---|---|---|---|
| Claude | 鑰匙圈項目 `Claude Code-credentials`（透過 `/usr/bin/security` 讀取） | `api.anthropic.com/api/oauth/usage` | 5 小時視窗、每週視窗、依模型的每週額度 |
| Codex | `~/.codex/auth.json`（或 `$CODEX_HOME/auth.json`） | `chatgpt.com/backend-api/wham/usage` | 5 小時視窗、每週視窗、方案 |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`（唯讀開啟） | `cursor.com/api/usage-summary`、`…/get-sand-usage-status` | Cursor 模型池（Auto / Composer / Grok）、API 模型池、隨需消費、每週 Grok Bot、本週期已花費金額 |

AgentBar 不會更新權杖。若某供應商顯示 *工作階段已過期*，開啟該用戶端一次即可，它會更新權杖，AgentBar 於下次重新整理時讀取。

## 面板

- 點選選單列圖示：所有供應商立即重新整理；載入期間顯示快取值。
- 進度條低於 60 % 為綠色，高於為黃色，達到通知門檻後為紅色。
- 每個額度顯示剩餘時間與確切重設時刻，例如 *2h 15m 後重設 · 週四 9月24日 20:00*。
- 額度旁的鈴鐺表示該額度的通知已開啟（在設定中設定）。
- 底列：統計 · 重新整理 · 設定 · 結束。

## 使用統計

底列的圖表按鈕會開啟統計視窗。頂部切換供應商與期間；將滑鼠移到圖表上可查看當日總計或某個模型的佔比。

| 供應商 | 資料來源 | 費用 |
|---|---|---|
| Claude | Claude Code 逐字稿（`~/.claude/projects/**/*.jsonl`），索引一次並依檔案快取 | 同等用量透過 API 的費用：輸入/輸出依牌價，快取寫入 ×1.25（5 分鐘 TTL）/ ×2（1 小時 TTL），快取讀取 ×0.1 |
| Codex | 工作階段記錄（`~/.codex/sessions/**/*.jsonl`） | OpenAI API 牌價；快取輸入 ×0.1。無公開價格的模型僅顯示 token |
| Cursor | Cursor 儀表板的使用事件，本機快取。首次開啟時選擇載入全部歷史或僅目前計費週期；之後只取得新事件 | Cursor 對每個要求回報的金額 |

**為什麼 AgentBar 的 Claude 總量與 Claude Code 的 `/stats` 不同。** Claude Code 逐行計算逐字稿，而包含多個內容區塊（思考、文字、工具呼叫）的回覆會被寫成共用同一筆用量記錄的多行，因此被重複計算。AgentBar 每則回覆只計一次並取最終用量值——這才是 API 實際計費的數字——並在旁邊列出 Claude Code 的數字以供參考。

索引 700 MB 逐字稿首次約需 10 秒，之後遠低於 1 秒。快取位於 `~/Library/Application Support/AgentBar/`。

## 通知

- 在設定 → 通知中開啟通知並選擇預設門檻（50–95 %）。
- 任一額度都可以在設定 → 通知中靜音或設定個別門檻。
- 每個額度在每個重設週期只通知一次。
- 每次重新整理時檢查額度：開啟自動重新整理時依排程檢查，否則僅在開啟面板時檢查。

## 設定

- **一般** — 自動重新整理間隔（關閉 / 1 / 5 / 15 / 30 / 60 分鐘）、顯示的供應商、語言、登入時啟動、更新。
- **通知** — 總開關、預設門檻、各額度規則。

## 更新

AgentBar 每天檢查一次 GitHub Releases，也會在你按下 *檢查更新* 時檢查。有新版本時面板會顯示 *更新* 按鈕。更新檔下載後，會以發布的檢查碼驗證 SHA-256，檢查 bundle 識別碼與版本，將舊應用程式移到垃圾桶並啟動新版本。你也可以在[發行頁面](https://github.com/funbool/agentbar/releases)手動安裝任一版本。

## 從原始碼建置

需要 Xcode 15 或更新版本（Swift 5.9）。無第三方相依套件。

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # 單元測試
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # 建置、複製到 /Applications 並啟動
```

除錯工具（執行 bundle 內的執行檔或 `.build/debug/AgentBar`）：

```bash
AgentBar --dump            # 取得每個供應商一次並印出解析後的額度
AgentBar --raw             # 印出每個端點的原始 JSON
AgentBar --stats           # 索引本機 Claude/Codex 記錄並印出總計
AgentBar --cursor-events   # 取得 Cursor 使用事件並印出總計
AgentBar --update          # 無介面執行完整更新流程
```

### 發行

```bash
./scripts/release.sh 0.2.0
```

此指令會提升 `Packaging/Info.plist` 中的版本號，建立 `v0.2.0` 標籤並推送。GitHub Actions 會執行測試、建置應用程式、將 `AgentBar.zip` 與 `AgentBar.zip.sha256` 發布為 release，執行中的副本會在下次檢查時取得。

## 隱私與安全

- **讀取：** Claude Code 的鑰匙圈項目、`~/.codex/auth.json`、Cursor 的 `state.vscdb`（唯讀）、本機逐字稿與工作階段記錄。
- **寫入：** `~/Library/Application Support/AgentBar/` 下的偏好設定與快取。
- **網路：** `api.anthropic.com`、`chatgpt.com`、`cursor.com`（你自己的使用資料）以及 `api.github.com` / `github.com`（檢查與下載更新）。沒有其他。
- 發行版本由 GitHub Actions 從已標籤的原始碼建置；工作流程位於 `.github/workflows/release.yml`。

## 疑難排解

| 症狀 | 處理方式 |
|---|---|
| *未登入 — 請開啟 …* | 在該用戶端登入一次；AgentBar 會在下次重新整理時讀取儲存的權杖。 |
| 鑰匙圈提示反覆出現 | 選擇 *永遠允許*。一段時間後再次出現表示 Claude Code 輪換了權杖。 |
| Cursor 沒有顯示 | 開啟 Cursor 一次以更新工作階段權杖，然後重新整理 AgentBar。 |
| 下載後應用程式無法開啟 | Gatekeeper — 見[安裝](#安裝)。 |
| 統計一直停在 *正在建立索引…* | 大型逐字稿資料夾的首次索引需要一些時間；之後使用快取。 |

## 致謝

端點研究參考了開源專案 [CodexBar](https://github.com/steipete/CodexBar)。

## 授權

[MIT](../LICENSE)
