#!/bin/bash
# 簡易デプロイスクリプト
# 使用方法: ./deploy.sh [BRANCH]

set -e  # エラーが発生したら即座に終了

# 設定
DEPLOY_TO="/var/www/costcalc"
REPO_URL="https://github.com/yourusername/costcalc.git"
BRANCH="${1:-main}"
SHARED_DIR="$DEPLOY_TO/shared"
CURRENT_DIR="$DEPLOY_TO/current"

echo "🚀 デプロイ開始: ブランチ $BRANCH"

# 共有ディレクトリの作成（初回のみ）
if [ ! -d "$SHARED_DIR" ]; then
  echo "📁 共有ディレクトリを作成中..."
  mkdir -p "$SHARED_DIR/log"
  mkdir -p "$SHARED_DIR/tmp/pids"
  mkdir -p "$SHARED_DIR/sockets"
  mkdir -p "$SHARED_DIR/storage"
fi

# リポジトリの更新またはクローン
if [ -d "$CURRENT_DIR/.git" ]; then
  echo "📥 最新のコードを取得中..."
  cd "$CURRENT_DIR"
  git fetch origin
  git reset --hard origin/$BRANCH
else
  echo "📥 リポジトリをクローン中..."
  git clone -b $BRANCH $REPO_URL "$CURRENT_DIR"
  cd "$CURRENT_DIR"
fi

# シンボリックリンクの作成
echo "🔗 共有ファイルのリンクを作成中..."
ln -nfs "$SHARED_DIR/log" "$CURRENT_DIR/log"
ln -nfs "$SHARED_DIR/tmp/pids" "$CURRENT_DIR/tmp/pids"
ln -nfs "$SHARED_DIR/tmp/sockets" "$CURRENT_DIR/tmp/sockets"
ln -nfs "$SHARED_DIR/storage" "$CURRENT_DIR/storage"

# 環境変数ファイルのコピー（存在する場合）
if [ -f "$SHARED_DIR/.env.production.local" ]; then
  ln -nfs "$SHARED_DIR/.env.production.local" "$CURRENT_DIR/.env.production.local"
fi

# master.keyのコピー（存在する場合）
if [ -f "$SHARED_DIR/master.key" ]; then
  ln -nfs "$SHARED_DIR/master.key" "$CURRENT_DIR/config/master.key"
fi

# Bundlerのインストール
echo "💎 Gemをインストール中..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# データベースのマイグレーション
echo "🗄️  データベースをマイグレーション中..."
RAILS_ENV=production bundle exec rails db:migrate

# アセットのプリコンパイル
echo "🎨 アセットをコンパイル中..."
RAILS_ENV=production bundle exec rails assets:precompile

# Pumaの再起動
echo "🔄 アプリケーションを再起動中..."
sudo systemctl restart costcalc

# nginxの設定をリロード（必要な場合）
if nginx -t 2>/dev/null; then
  echo "🔄 Nginxをリロード中..."
  sudo nginx -s reload
fi

echo "✅ デプロイ完了！"
echo "📊 ステータス確認: sudo systemctl status costcalc"
echo "📋 ログ確認: journalctl -u costcalc -f"