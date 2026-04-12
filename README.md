# Koyomi CLI

家族予実共有アプリ [Koyomi](https://koyomi.belulu.dev) のコマンドラインツール。

## インストール

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/belulu-dev/koyomi-cli/main/install.sh | sh
```

`/usr/local/bin` が存在しない環境（NixOS 等）では自動的に `~/.local/bin` にインストールされます。`/usr/local/bin` に書き込み権限がない場合は `sudo` で実行されます。

インストール先を明示的に変更するには:

```bash
curl -fsSL https://raw.githubusercontent.com/belulu-dev/koyomi-cli/main/install.sh | KOYOMI_INSTALL_DIR=$HOME/.local/bin sh
```

### NixOS

`/usr/local/bin` が存在しないため、デフォルトで `~/.local/bin` にインストールされます。

```bash
curl -fsSL https://raw.githubusercontent.com/belulu-dev/koyomi-cli/main/install.sh | sh
```

`~/.local/bin` が PATH に含まれていることを確認してください。

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/belulu-dev/koyomi-cli/main/install.ps1 | iex
```

`%LOCALAPPDATA%\koyomi-cli\` にインストールされ、ユーザー PATH に自動追加されます。

### 手動インストール

[Releases](https://github.com/belulu-dev/koyomi-cli/releases) からお使いの OS に合ったバイナリをダウンロードして、パスの通ったディレクトリに配置してください。

```bash
tar xzf koyomi-*.tar.gz
sudo mv koyomi-*/koyomi /usr/local/bin/
```

### アップグレード

```bash
koyomi upgrade
```

## 認証

```bash
koyomi login              # ブラウザ認証（デフォルト）
koyomi login --device     # デバイスコード方式（SSH/ヘッドレス環境向け）
```

| オプション | 説明 |
|-----------|------|
| `--base-url` | API の URL（デフォルト: `https://koyomi.belulu.dev`） |
| `--device` | デバイスコード方式でログイン |

SSH 環境ではブラウザが使えないため、`--device` でデバイスコード方式を使用してください。

```bash
koyomi logout    # セッション破棄
koyomi whoami    # アカウント情報を表示
```

## コマンド一覧

| コマンド | 説明 |
|----------|------|
| `koyomi login` | ログイン |
| `koyomi logout` | ログアウト |
| `koyomi whoami` | ログイン中のアカウント情報 |
| `koyomi plan` | 予定管理（list/create/show/edit/delete/schedule/complete/archive/reopen） |
| `koyomi actual` | 実績管理（list/create/show/edit/delete） |
| `koyomi place` | 場所管理（list/create/show/edit/delete） |
| `koyomi checklist` | チェックリスト管理（list/add/check/uncheck/remove） |
| `koyomi collection` | 繰り返し管理（list/create/show/edit/delete/add-plan/remove-plan） |
| `koyomi group` | グループ管理（list/switch/create） |
| `koyomi member` | メンバー管理（list/add/edit/remove/invite） |
| `koyomi member-group` | メンバーグループ管理（list/create/show/edit/delete） |
| `koyomi comment` | コメント管理（list/add/edit/delete） |
| `koyomi activity` | アクティビティ履歴 |
| `koyomi dashboard` | 達成率・統計表示 |
| `koyomi calendar` | 月間カレンダー表示 |
| `koyomi upgrade` | 最新バージョンに更新 |
| `koyomi version` | バージョン表示 |

## 共通オプション

### 出力形式

照会系コマンドは `--format` で出力形式を切り替えられます。

```bash
koyomi plan list --format table   # テーブル形式（デフォルト）
koyomi plan list --format json    # JSON（スクリプト連携向け）
koyomi plan list --format csv     # CSV
```

## 予定 (Plan)

### 一覧

```bash
koyomi plan list [オプション]
```

| オプション | 説明 |
|-----------|------|
| `--status` | ステータスフィルタ: `draft` / `scheduled` / `done` / `archived` |
| `--from` | 開始日 YYYY-MM-DD |
| `--to` | 終了日 YYYY-MM-DD |
| `--members` | メンバーIDでフィルタ |
| `--format` | 出力形式: `table` / `json` / `csv` |

```bash
koyomi plan list
koyomi plan list --status scheduled
koyomi plan list --from 2026-01-01 --to 2026-03-31
```

### 作成

```bash
koyomi plan create [オプション]
```

| オプション | 説明 |
|-----------|------|
| `--title` | タイトル（必須） |
| `--start-at` | 開始日時 (YYYY-MM-DD or YYYY-MM-DDTHH:MM) |
| `--end-at` | 終了日時 |
| `--all-day` | 終日イベント |
| `--place-id` | 場所ID |
| `--memo` | メモ |
| `--status` | ステータス: `draft` / `scheduled`（デフォルト: scheduled） |
| `--member-ids` | メンバーID（カンマ区切り） |

```bash
koyomi plan create --title "家族旅行" --start-at 2026-04-01 --end-at 2026-04-03 --all-day
koyomi plan create --title "会議" --start-at 2026-03-28T14:00 --member-ids id1,id2
```

### 詳細・編集・削除

```bash
koyomi plan show <id>
koyomi plan edit <id> --title "新しいタイトル" --memo "更新メモ"
koyomi plan delete <id>
```

### ステータス遷移

```bash
koyomi plan schedule <id>   # draft → scheduled（確定）
koyomi plan complete <id>   # scheduled → done（完了、Actual 自動生成）
koyomi plan archive <id>    # → archived（保留）
koyomi plan reopen <id>     # archived → draft（再検討）
```

## 実績 (Actual)

### 一覧

```bash
koyomi actual list [オプション]
```

| オプション | 説明 |
|-----------|------|
| `--from` | 開始日 YYYY-MM-DD |
| `--to` | 終了日 YYYY-MM-DD |
| `--members` | メンバーIDでフィルタ |

### 作成

```bash
koyomi actual create [オプション]
```

| オプション | 説明 |
|-----------|------|
| `--title` | タイトル（必須） |
| `--started-at` | 開始日時 |
| `--ended-at` | 終了日時 |
| `--all-day` | 終日イベント |
| `--place-id` | 場所ID |
| `--memo` | メモ |
| `--rating` | 評価 (1-5) |
| `--member-ids` | メンバーID（カンマ区切り） |

```bash
koyomi actual create --title "映画鑑賞" --started-at 2026-03-28T19:00 --rating 5
```

### 詳細・編集・削除

```bash
koyomi actual show <id>
koyomi actual edit <id> --rating 4 --memo "楽しかった！"
koyomi actual delete <id>
```

## 場所 (Place)

### 一覧

```bash
koyomi place list [オプション]
```

| オプション | 説明 |
|-----------|------|
| `--category` | カテゴリフィルタ: `hotel` / `restaurant` / `activity` / `park` / `shopping` / `other` |
| `--wishlist` | ウィッシュリストのみ表示 |

### 作成

```bash
koyomi place create [オプション]
```

| オプション | 説明 |
|-----------|------|
| `--name` | 名前（必須） |
| `--category` | カテゴリ（必須） |
| `--wishlist` | ウィッシュリストに追加 |
| `--address` | 住所 |
| `--url` | URL |
| `--memo` | メモ |

```bash
koyomi place create --name "イタリア料理店" --category restaurant --address "東京都渋谷区"
koyomi place create --name "スキー場" --category activity --wishlist
```

### 詳細・編集・削除

```bash
koyomi place show <id>     # 統計・訪問履歴も表示
koyomi place edit <id> --name "新しい店名"
koyomi place delete <id>
```

## チェックリスト

```bash
koyomi checklist list <plan-id>                  # 一覧表示
koyomi checklist add <plan-id> "荷造りをする"     # 項目追加
koyomi checklist check <plan-id> <item-id>       # 完了にする
koyomi checklist uncheck <plan-id> <item-id>     # 未完了に戻す
koyomi checklist remove <plan-id> <item-id>      # 項目削除
```

## 繰り返し (Collection)

```bash
koyomi collection list
koyomi collection create "毎週の会議" --start-date 2026-04-01 --end-date 2026-12-31
koyomi collection show <id>
koyomi collection edit <id> --title "新しいタイトル"
koyomi collection delete <id>
koyomi collection add-plan <collection-id> <plan-id>
koyomi collection remove-plan <collection-id> <plan-id>
```

## グループ・メンバー

### グループ

```bash
koyomi group list                          # グループ一覧
koyomi group switch <id|name>              # アクティブグループ切替
koyomi group create "山田家"               # グループ作成
koyomi group create "田中家" --member-name "田中太郎"
```

### メンバー

```bash
koyomi member list                                       # メンバー一覧
koyomi member add "田中太郎" --color "#FF5733" --avatar "👩"  # メンバー追加
koyomi member edit <id> --name "新しい名前"               # メンバー編集
koyomi member remove <id>                                # メンバー削除
koyomi member invite <member-id> --email user@example.com # 招待メール送信
```

### メンバーグループ

```bash
koyomi member-group list
koyomi member-group create "家族全員" --color "#00FF00" --members "id1,id2,id3"
koyomi member-group show <id>
koyomi member-group edit <id> --members "id1,id2"
koyomi member-group delete <id>
```

## コメント

```bash
koyomi comment list --plan <plan-id>                           # Plan のコメント一覧
koyomi comment add "良いアイデア！" --plan <plan-id>            # コメント投稿
koyomi comment add "楽しかった" --actual <actual-id>            # Actual にコメント
koyomi comment edit <comment-id> "修正したコメント"              # コメント編集
koyomi comment delete <comment-id>                             # コメント削除
```

## ダッシュボード・カレンダー

```bash
koyomi dashboard                                    # 達成率・統計
koyomi dashboard --from 2026-01-01 --to 2026-03-31  # 期間指定
koyomi calendar                                     # 当月のカレンダー
koyomi calendar 2026-04                             # 指定月のカレンダー
koyomi activity list                                # アクティビティ履歴
koyomi activity list --limit 50                     # 件数指定
```

## 設定ファイル

認証情報は `~/.koyomi-cli/credentials.json` に保存されます。

## ライセンス

Proprietary
