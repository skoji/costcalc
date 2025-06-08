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

## デプロイメント

このアプリケーションは複数の方法でデプロイ可能です。

### 方法1: 既存VPSへの相乗りデプロイ（nginx + Puma）

既存のVPSに他のサービスと共存させる形でデプロイする方法です。

#### 前提条件
- Ubuntu 20.04以上
- Ruby 3.4.3
- nginx
- systemd
- SQLite3

#### セットアップ手順

1. **アプリケーションディレクトリの準備**
```bash
sudo mkdir -p /var/www/costcalc
sudo chown deploy:deploy /var/www/costcalc
cd /var/www/costcalc
git clone https://github.com/yourusername/costcalc.git current
mkdir -p shared/sockets shared/log shared/tmp/pids shared/storage
```

2. **設定ファイルのコピーと編集**
```bash
# nginx設定
sudo cp current/config/deploy.example/nginx/costcalc.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/costcalc.conf /etc/nginx/sites-enabled/
# server_nameを実際のドメインに変更

# systemd設定
sudo cp current/config/deploy.example/systemd/costcalc.service /etc/systemd/system/
# 必要に応じてパスやユーザー名を調整
```

3. **環境変数の設定**
```bash
cd /var/www/costcalc/current
cp .env.example .env.production.local
# 編集して必要な値を設定（特にRAILS_MASTER_KEY）
```

4. **初回セットアップ**
```bash
bundle install --deployment --without development test
RAILS_ENV=production bundle exec rails db:create db:migrate
RAILS_ENV=production bundle exec rails assets:precompile
```

5. **サービスの開始**
```bash
sudo systemctl daemon-reload
sudo systemctl enable costcalc
sudo systemctl start costcalc
sudo nginx -s reload
```

6. **デプロイ用スクリプトの設定（オプション）**
```bash
# デプロイスクリプトをコピー
cp config/deploy.example/scripts/deploy.sh /var/www/costcalc/
chmod +x /var/www/costcalc/deploy.sh
# 必要に応じてスクリプトの設定値を編集

# 今後のデプロイは以下で実行
/var/www/costcalc/deploy.sh
```

### 方法2: Fly.io へのデプロイ

Fly.ioは分散型のアプリケーションプラットフォームで、SQLiteアプリケーションに最適です。

#### 前提条件
- Fly CLIのインストール: https://fly.io/docs/hands-on/install-flyctl/
- Fly.ioアカウント

#### セットアップ手順

1. **Fly.ioへのログイン**
```bash
fly auth login
```

2. **アプリケーションの作成**
```bash
cp fly.toml.example fly.toml
# appの値をユニークな名前に変更（例: costcalc-yourname）
fly apps create costcalc-yourname
```

3. **シークレットの設定**
```bash
fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
```

4. **ボリュームの作成**（データ永続化用）
```bash
fly volumes create costcalc_storage --region nrt --size 1
```

5. **デプロイ**
```bash
fly deploy
```

6. **データベースのセットアップ**
```bash
fly ssh console -C "bin/rails db:migrate"
```

7. **データベースの初期化（必要な場合）**
```bash
fly ssh console -C "bin/rails db:seed"
```

### 方法3: Kamal を使用したDockerデプロイ

詳細は[Kamal公式ドキュメント](https://kamal-deploy.org/)を参照してください。
基本的な設定は`config/deploy.yml`に含まれています。

### データベースバックアップ

#### SQLiteの場合

1. **手動バックアップ**
```bash
# 本番データベースのバックアップ
sqlite3 storage/production.sqlite3 ".backup storage/backup_$(date +%Y%m%d).sqlite3"

# リストア方法
cp storage/backup_20241206.sqlite3 storage/production.sqlite3
```

2. **自動バックアップの設定（VPS環境）**
```bash
# バックアップスクリプトを設置
sudo cp config/deploy.example/scripts/backup.sh /usr/local/bin/costcalc-backup
sudo chmod +x /usr/local/bin/costcalc-backup

# cronジョブの設定
sudo cp config/deploy.example/cron/costcalc-backup /etc/cron.d/
sudo chmod 644 /etc/cron.d/costcalc-backup
```

3. **Fly.ioでのバックアップ**
```bash
# スナップショットの作成
fly volumes snapshots create vol_xxxxx

# スナップショット一覧
fly volumes snapshots list vol_xxxxx

# ローカルへのダウンロード
fly ssh console -C "cat /rails/storage/production.sqlite3" > backup.sqlite3
```

### バックアップのベストプラクティス

1. **3-2-1ルール**
   - 3つのコピー（本番 + バックアップ2つ）
   - 2つの異なるメディア（ローカル + クラウド）
   - 1つはオフサイト（別の場所）

2. **定期的なリストアテスト**
   - 月1回はバックアップからのリストアをテスト
   - 手順書を最新に保つ

3. **監視**
   - バックアップジョブの成功/失敗を監視
   - ディスク容量の監視

### 本番環境での注意事項

1. **セキュリティ**
   - 必ず`RAILS_MASTER_KEY`を設定してください
   - 本番環境では強力なパスワードポリシーを設定してください
   - 定期的にセキュリティアップデートを適用してください

2. **パフォーマンス**
   - 必要に応じて`config/puma.rb`のワーカー数を調整してください
   - nginxのキャッシュ設定を適切に行ってください

3. **監視**
   - アプリケーションログを定期的に確認してください
   - システムリソース（CPU、メモリ、ディスク）を監視してください

## 本番環境への移行

1. 既存のcostcalc-legacyアプリケーションを停止
2. データベースファイルをバックアップ
3. 新しいRails 8アプリケーションをデプロイ
4. インポートタスクでデータ移行
5. 動作確認後にDNS切り替え

## 既存アプリケーションとの違い

- Rails 6.0 → Rails 8.0
- jQuery + Bootstrap → Turbo + Stimulus + Tailwind CSS
- 原価率30%のハードコードを削除し設定可能へ
- より高速なWebpackerからimportmapへの移行
