# 本番環境デプロイガイド

このディレクトリには、systemdとnginxを使用した本番環境へのデプロイに必要な設定ファイルの例が含まれています。

## ディレクトリ構成

- `nginx/` - Nginx設定ファイル
- `systemd/` - systemdサービスファイル
- `scripts/` - デプロイ・バックアップスクリプト
- `cron/` - cronジョブ設定

## デプロイ手順

### 1. アプリケーションのセットアップ

```bash
# アプリケーションディレクトリの作成
sudo mkdir -p /var/www/costcalc/current
sudo chown deploy:deploy /var/www/costcalc

# アプリケーションのクローン
cd /var/www/costcalc/current
git clone https://github.com/yourusername/costcalc.git .

# Rubyとbundlerのインストール（rbenvなどを使用）
bundle install --deployment --without development test

# データベースのセットアップ
RAILS_ENV=production bin/rails db:create db:migrate

# アセットのプリコンパイル
RAILS_ENV=production bin/rails assets:precompile

# マスターキーの設定
echo "your-master-key" > config/master.key
chmod 600 config/master.key
```

### 2. systemdサービスの設定

```bash
# サービスファイルのコピー
sudo cp config/deploy.example/systemd/costcalc.service /etc/systemd/system/

# systemdの再読み込みとサービスの有効化
sudo systemctl daemon-reload
sudo systemctl enable costcalc
sudo systemctl start costcalc

# ステータス確認
sudo systemctl status costcalc
```

### 3. Nginxの設定

```bash
# 設定ファイルのコピー
sudo cp config/deploy.example/nginx/costcalc.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/costcalc.conf /etc/nginx/sites-enabled/

# 設定のテスト
sudo nginx -t

# Nginxの再起動
sudo systemctl restart nginx
```

## ソケットファイルについて

このセットアップでは、PumaはUnixソケットを使用してNginxと通信します：

- ソケットパス: `/var/www/costcalc/current/shared/sockets/puma.sock`
- ステートファイル: `/var/www/costcalc/current/shared/tmp/pids/puma.state`

これらのディレクトリは、Pumaが起動時に自動的に作成します。

## トラブルシューティング

### ソケットファイルが見つからない

```bash
# Pumaの実行状態を確認
sudo systemctl status costcalc

# ログを確認
sudo journalctl -u costcalc -f

# ソケットファイルの存在確認
ls -la /var/www/costcalc/current/shared/sockets/
```

### 権限エラー

```bash
# アプリケーションディレクトリの所有者を確認
ls -la /var/www/costcalc/

# 必要に応じて所有者を変更
sudo chown -R deploy:deploy /var/www/costcalc/current
```

### Nginxが502エラーを返す

1. Pumaが正常に起動しているか確認
2. ソケットファイルのパスが正しいか確認
3. SELinuxが有効な場合は、適切な設定を行う

```bash
# SELinuxの確認（CentOS/RHEL）
getenforce

# 必要に応じてhttpd_can_network_connectを有効化
sudo setsebool -P httpd_can_network_connect 1
```