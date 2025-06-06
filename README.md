# CostCalc (Rails 8)

Rails 8版の原価計算アプリケーション。既存のcostcalc-legacyアプリケーションからのアップグレード版です。

## システム要件

* Ruby 3.4.3+
* Rails 8.0+
* SQLite3

## セットアップ

```bash
# 依存関係のインストール
bundle install

# データベースの作成とマイグレーション
bin/rails db:create db:migrate

# 開発サーバーの起動
bin/dev
```

## 既存データのインポート

costcalc-legacyからデータを移行する場合：

### 方法1: SQLite3データベースファイルから直接インポート

```bash
# 既存のデータベースファイルを指定してインポート
LEGACY_DB_PATH=/path/to/legacy/db/development.sqlite3 bin/rails import:from_legacy

# 確認プロンプトをスキップしたい場合
FORCE=true LEGACY_DB_PATH=/path/to/legacy/db/development.sqlite3 bin/rails import:from_legacy
```

### 方法2: SQLダンプファイルからインポート

```bash
# 既存データベースからSQLダンプを作成（レガシー側で実行）
sqlite3 /path/to/legacy/db/development.sqlite3 .dump > legacy_dump.sql

# SQLダンプからインポート
SQL_DUMP_PATH=/path/to/legacy_dump.sql bin/rails import:from_sql_dump
```

### データ検証

インポート後にデータの整合性を確認：

```bash
bin/rails import:validate
```

### テスト用サンプルデータの作成

```bash
# サンプルのレガシーデータベースを作成
bin/rails import:create_sample_legacy

# 作成されたサンプルデータでインポートテスト
LEGACY_DB_PATH=tmp/sample_legacy.sqlite3 bin/rails import:from_legacy
```

## 開発

### テストの実行

```bash
# 全テストの実行
bin/rails test

# 特定のテストファイルの実行
bin/rails test test/models/material_test.rb

# インポート機能のテスト
bin/rails test test/lib/import_test.rb
```

### データベースのリセット

```bash
# データベースを削除して再作成
bin/rails db:drop db:create db:migrate
```

## 主な機能

- 材料管理（価格、単位付き）
- 製品管理（原材料の組み合わせ）
- 原価計算（材料費から製品原価を自動計算）
- マルチテナント対応（ユーザーごとにデータ分離）

## アーキテクチャ

### データモデル

```
User (ユーザー)
├── Materials (材料)
│   ├── MaterialQuantities (材料数量)
│   └── ProductIngredients (製品原材料)
├── Products (製品)
│   └── ProductIngredients (製品原材料)
└── Units (単位)
```

### 技術スタック

- **バックエンド**: Rails 8.0, SQLite3
- **フロントエンド**: Turbo, Stimulus, Tailwind CSS
- **テスト**: Minitest
- **デプロイ**: Kamal (Docker)

## 本番環境への移行

1. 既存のcostcalc-legacyアプリケーションを停止
2. データベースファイルをバックアップ
3. 新しいRails 8アプリケーションをデプロイ
4. インポートタスクでデータ移行
5. 動作確認後にDNS切り替え

## 既存アプリケーションとの違い

- Rails 6.0 → Rails 8.0
- jQuery + Bootstrap → Turbo + Stimulus + Tailwind CSS
- 原価率30%のハードコードを削除（設定可能にする予定）
- より高速なWebpackerからimportmapへの移行
