<!-- LANGS -->
[🇬🇧 English](../README.md) · [🇷🇺 Русский](README.ru.md) · [🇺🇦 Українська](README.uk.md) · [🇩🇪 Deutsch](README.de.md) · [🇫🇷 Français](README.fr.md) · [🇪🇸 Español](README.es.md) · [🇵🇹 Português](README.pt-PT.md) · [🇧🇷 Português (Brasil)](README.pt-BR.md) · [🇵🇱 Polski](README.pl.md) · [🇨🇿 Čeština](README.cs.md) · [🇭🇺 Magyar](README.hu.md) · [🇹🇷 Türkçe](README.tr.md) · [🇰🇿 Қазақша](README.kk.md) · [🇮🇳 हिन्दी](README.hi.md) · **🇯🇵 日本語** · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md)
<!-- /LANGS -->

# AgentBar

**Claude**、**Codex**、**Cursor** の利用上限をどれだけ消費したかをメニューバーに表示する、軽量な macOS アプリです。トークン統計と、同じ使用量を公開 API で行った場合の費用も確認できます。

[![CI](https://github.com/funbool/agentbar/actions/workflows/ci.yml/badge.svg)](https://github.com/funbool/agentbar/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/funbool/agentbar?display_name=tag)](https://github.com/funbool/agentbar/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](../LICENSE)

## 機能

- **上限を一目で** — Claude と Codex の 5 時間・週間ウィンドウ、Cursor のプラン内使用量プール。それぞれにプログレスバー、リセットまでの残り時間、正確なリセット日時を表示。
- **モデル別の週間上限**（Opus、Sonnet、Fable など）を Claude の API が返した時点で表示。
- **使用統計** — 種類別トークン、費用、モデル別・プロジェクト別の内訳、日別チャート。今日 / 7 日間 / 30 日間 / 全期間。
- **通知** — 上限がしきい値を超えたときに通知。全体のデフォルトと、上限ごとのルール（ミュート、個別しきい値）。
- **自動更新（任意）**、ログイン時起動、17 の表示言語。
- **GitHub Releases からの OTA アップデート**（SHA-256 で検証）。
- **アカウント不要、テレメトリなし。** AgentBar は公式クライアントが Mac に保存済みのトークンを読み取り、各プロバイダの API とだけ通信します。

## 動作要件

- macOS 14 Sonoma 以降（Apple シリコンまたは Intel）。
- [Claude Code](https://claude.com/claude-code)、[Codex](https://openai.com/codex)（CLI またはデスクトップアプリ）、[Cursor](https://cursor.com) のいずれかにサインイン済みであること。使わないプロバイダは設定で非表示にできます。

## インストール

1. [最新リリース](https://github.com/funbool/agentbar/releases/latest)から `AgentBar.zip` をダウンロードします。
2. 解凍して `AgentBar.app` を `/Applications` に移動します。
3. アプリを開きます。ログイン項目として自動登録されます（設定でオフにできます）。

**Gatekeeper。** リリースはアドホック署名で、公証はされていません。ダウンロード直後のコピーを macOS が開けない場合は、右クリック → *開く* を一度選ぶか、隔離属性を外してください。

```bash
xattr -dr com.apple.quarantine /Applications/AgentBar.app
```

**キーチェーンの確認。** 最初の Claude 更新時に、`security` が *Claude Code-credentials* 項目を読み取ってよいか macOS が尋ねます。**常に許可** を選んでください。Claude Code がトークンをローテーションした後に再度表示されることがありますが、正常な動作です。

[ソースからビルド](#ソースからビルド)することもできます。

## 仕組み

AgentBar はサインインを求めません。各クライアントが Mac に保存している認証情報を読み取り、クライアントと同じエンドポイントを呼び出します。

| プロバイダ | 認証情報の読み取り元 | エンドポイント | 表示内容 |
|---|---|---|---|
| Claude | キーチェーン項目 `Claude Code-credentials`（`/usr/bin/security` 経由で読み取り） | `api.anthropic.com/api/oauth/usage` | 5 時間ウィンドウ、週間ウィンドウ、モデル別週間上限 |
| Codex | `~/.codex/auth.json`（または `$CODEX_HOME/auth.json`） | `chatgpt.com/backend-api/wham/usage` | 5 時間ウィンドウ、週間ウィンドウ、プラン |
| Cursor | `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`（読み取り専用） | `cursor.com/api/usage-summary`、`…/get-sand-usage-status` | Cursor モデルプール（Auto / Composer / Grok）、API モデルプール、オンデマンド支出、週間 Grok Bot、今サイクルの支出 |

AgentBar はトークンを更新しません。*セッション期限切れ* と表示されたら、そのクライアントを一度開いてください。トークンが更新され、次回の更新時に AgentBar が取り込みます。

## パネル

- メニューバーのアイコンをクリックすると全プロバイダを即時更新。読み込み中はキャッシュ値を表示します。
- バーは 60 % 未満で緑、それ以上で黄、通知しきい値に達すると赤になります。
- 各上限には残り時間と正確なリセット時刻を表示します（例：*2h 15m後にリセット · 9/24(木) 20:00*）。
- 上限の横にベルが表示されている場合、その上限の通知がオンです（設定で構成します）。
- フッター：統計 · 更新 · 設定 · 終了。

## 使用統計

フッターのチャートボタンで統計ウィンドウを開きます。上部でプロバイダと期間を切り替え、チャートにカーソルを合わせると日の合計や各モデルの内訳を確認できます。

| プロバイダ | ソース | 費用 |
|---|---|---|
| Claude | Claude Code のトランスクリプト（`~/.claude/projects/**/*.jsonl`）。一度インデックスし、ファイル単位でキャッシュ | 同じ使用量を API で行った場合の金額：入出力は定価、キャッシュ書き込み ×1.25（5 分 TTL）/ ×2（1 時間 TTL）、キャッシュ読み取り ×0.1 |
| Codex | セッションログ（`~/.codex/sessions/**/*.jsonl`） | OpenAI API の定価。キャッシュ入力 ×0.1。公開価格のないモデルはトークンのみ表示 |
| Cursor | Cursor ダッシュボードの使用イベント（ローカルにキャッシュ）。初回に全履歴か現在の請求サイクルのみかを選択し、以降は新しいイベントだけを取得 | Cursor がリクエストごとに報告する金額 |

**AgentBar の Claude 合計が Claude Code の `/stats` と異なる理由。** Claude Code はトランスクリプトの各行を数えます。複数ブロック（思考、テキスト、ツール呼び出し）からなる応答は、同じ使用量レコードを共有する複数行として書き込まれるため、複数回カウントされます。AgentBar は各応答を最終的な使用量で 1 回だけ数え（これが API の実際の請求量です）、参考として Claude Code の数値も併記します。

700 MB のトランスクリプトのインデックス作成は初回約 10 秒、以降は 1 秒未満です。キャッシュは `~/Library/Application Support/AgentBar/` にあります。

## 通知

- 設定 → 通知で通知をオンにし、デフォルトのしきい値（50–95 %）を選びます。
- 各上限は、設定 → 通知でミュートしたり個別のしきい値を設定したりできます。
- 通知は上限ごと・リセットサイクルごとに 1 回です。
- 上限は更新のたびに確認されます。自動更新がオンならスケジュールに従い、オフならパネルを開いたときのみです。

## 設定

- **一般** — 更新間隔（オフ / 1 / 5 / 15 / 30 / 60 分）、表示するプロバイダ、言語、ログイン時起動、アップデート。
- **通知** — 全体のオン/オフ、デフォルトしきい値、上限ごとのルール。

## アップデート

AgentBar は 1 日 1 回、および *アップデートを確認* を押したときに GitHub Releases を確認します。新しいバージョンがあるとパネルに *アップデート* ボタンが表示されます。ダウンロード後、SHA-256 を公開チェックサムと照合し、バンドル ID とバージョンを確認して、旧アプリをゴミ箱へ移動し、新アプリを起動します。[リリースページ](https://github.com/funbool/agentbar/releases)から手動でインストールすることもできます。

## ソースからビルド

Xcode 15 以降（Swift 5.9）が必要です。サードパーティ依存はありません。

```bash
git clone https://github.com/funbool/agentbar.git
cd agentbar
swift test                 # ユニットテスト
./scripts/build.sh         # -> build/AgentBar.app
./scripts/install.sh       # ビルドして /Applications にコピーし起動
```

デバッグ用ヘルパー（バンドル内のバイナリまたは `.build/debug/AgentBar` を実行）：

```bash
AgentBar --dump            # 全プロバイダを一度取得し、解析済みの上限を出力
AgentBar --raw             # 各エンドポイントの生 JSON を出力
AgentBar --stats           # ローカルの Claude/Codex ログをインデックスし合計を出力
AgentBar --cursor-events   # Cursor の使用イベントを取得し合計を出力
AgentBar --update          # アップデートの全工程を UI なしで実行
```

### リリース手順

```bash
./scripts/release.sh 0.2.0
```

`Packaging/Info.plist` のバージョンを上げ、タグ `v0.2.0` を作成してプッシュします。GitHub Actions がテストを実行し、アプリをビルドして `AgentBar.zip` と `AgentBar.zip.sha256` をリリースとして公開します。実行中のコピーは次回の確認時に取り込みます。

## プライバシーとセキュリティ

- **読み取り：** Claude Code のキーチェーン項目、`~/.codex/auth.json`、Cursor の `state.vscdb`（読み取り専用）、ローカルのトランスクリプトとセッションログ。
- **書き込み：** `~/Library/Application Support/AgentBar/` 配下の設定とキャッシュ。
- **ネットワーク：** `api.anthropic.com`、`chatgpt.com`、`cursor.com`（ご自身の使用データ）、および `api.github.com` / `github.com`（アップデートの確認とダウンロード）。それ以外はありません。
- リリースはタグ付きソースから GitHub Actions がビルドします。ワークフローは `.github/workflows/release.yml` にあります。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| *未ログイン — … を開いてください* | そのクライアントに一度サインインしてください。次回の更新で保存済みトークンを読み取ります。 |
| キーチェーンの確認が何度も出る | *常に許可* を選んでください。しばらくして再表示された場合は Claude Code がトークンをローテーションしています。 |
| Cursor に何も表示されない | Cursor を一度開いてセッショントークンを更新し、AgentBar を更新してください。 |
| ダウンロード後にアプリが開かない | Gatekeeper — [インストール](#インストール)を参照。 |
| 統計が *インデックス作成中…* のまま | 大きなトランスクリプトの初回インデックスには時間がかかります。以降はキャッシュを使用します。 |

## 謝辞

エンドポイントの調査にはオープンソースプロジェクト [CodexBar](https://github.com/steipete/CodexBar) が参考になりました。

## ライセンス

[MIT](../LICENSE)
