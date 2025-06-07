#!/bin/bash
# SQLite3データベースのバックアップスクリプト
# 使用方法: ./backup.sh

set -e  # エラーが発生したら即座に終了

# 設定
BACKUP_DIR="/var/backups/costcalc"
APP_DIR="/var/www/costcalc/current"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30  # バックアップ保持日数

# バックアップディレクトリ作成
mkdir -p "$BACKUP_DIR"

echo "🔄 バックアップ開始: $(date)"

# SQLiteデータベースのバックアップ
DB_FILE="$APP_DIR/storage/production.sqlite3"
if [ -f "$DB_FILE" ]; then
  echo "📁 データベースをバックアップ中..."
  
  # SQLiteの.backupコマンドを使用（データ整合性を保証）
  sqlite3 "$DB_FILE" ".backup '$BACKUP_DIR/db_backup_$DATE.sqlite3'"
  
  # バックアップファイルを圧縮
  gzip "$BACKUP_DIR/db_backup_$DATE.sqlite3"
  echo "✅ データベースバックアップ完了: db_backup_$DATE.sqlite3.gz"
else
  echo "⚠️  データベースファイルが見つかりません: $DB_FILE"
fi

# アップロードファイルのバックアップ（Active Storage使用時）
STORAGE_DIR="$APP_DIR/storage"
if [ -d "$STORAGE_DIR" ] && [ "$(ls -A $STORAGE_DIR)" ]; then
  echo "📁 ストレージディレクトリをバックアップ中..."
  tar -czf "$BACKUP_DIR/storage_backup_$DATE.tar.gz" -C "$APP_DIR" storage/
  echo "✅ ストレージバックアップ完了: storage_backup_$DATE.tar.gz"
fi

# 古いバックアップの削除
echo "🗑️  $RETENTION_DAYS 日以上古いバックアップを削除中..."
find "$BACKUP_DIR" -name "db_backup_*.sqlite3.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "storage_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

# バックアップサイズの確認
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "📊 現在のバックアップ総サイズ: $BACKUP_SIZE"

# バックアップ一覧
echo "📋 最新のバックアップ:"
ls -lht "$BACKUP_DIR" | head -n 6

echo "✅ バックアップ完了: $(date)"