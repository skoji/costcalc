# CLAUDE.md - プロジェクト情報

## プロジェクト概要
このプロジェクトは、製品の原価計算を行うRailsアプリケーションです。材料費から製品の原価を自動計算し、利益率を考慮した販売価格を提案します。

## 技術スタック
- Ruby on Rails 8.0.2
- Ruby 3.3.0
- SQLite3
- Tailwind CSS
- Stimulus.js
- Turbo

## 主な機能
1. **材料管理**
   - 材料の登録・編集・削除
   - 材料ごとの単位と価格設定
   - 材料一覧の検索機能

2. **製品管理**
   - 製品の登録・編集・削除
   - 材料を組み合わせた原価計算
   - 製品一覧の検索機能
   - 材料のプルダウン選択（文字入力で絞り込み可能）

3. **原価計算**
   - 材料費の自動集計
   - 仕込み数での単価計算
   - 利益率を考慮した販売価格表示

## 開発時の注意事項

### フォームオブジェクトパターン
- `MaterialForm`と`ProductForm`を使用してネストした属性を管理
- 編集時は既存のデータを削除せずに更新するよう注意

### JavaScript/Stimulus
- 材料追加は動的にフォームフィールドを追加
- 材料選択時に単位が自動的に絞り込まれる
- 製品一覧からの戻り時に自動スクロール機能あり

### テスト実行方針

#### 通常のテスト（ローカル実行推奨）
```bash
# モデル、コントローラー、統合テスト
bin/rails test

# 特定のテスト実行
bin/rails test test/forms/product_form_test.rb
bin/rails test test/controllers/products_controller_test.rb
```

#### システムテスト（CI専用）
- **ローカル実行は非推奨**: 環境の差異により結果が不安定
- **CI環境で自動実行**: プルリクエスト作成時に自動実行される
- **手動実行**: GitHubのActionsタブから必要に応じて実行可能

**理由:**
- ブラウザ環境の違い（ヘッドレスChrome設定、フォント等）
- ロケール設定の環境差異  
- ネットワークやタイミングの問題

開発時は通常のテストで十分な品質を担保し、E2Eテストは統合確認としてCI環境で実行する方針です。

### よく使うコマンド
```bash
# サーバー起動
bin/rails server

# コンソール起動
bin/rails console

# マイグレーション実行
bin/rails db:migrate

# テスト実行
bin/rails test

# Lintチェック
bin/rails lint
```

## 最近の変更点
- 製品編集時に材料が消える問題を修正
- 材料選択をテキスト入力＋プルダウンのハイブリッド方式に変更
- 製品詳細画面に上部ナビゲーションを追加
- 製品一覧への戻り時に該当製品へ自動スクロール
- 材料追加ボタンを上下に配置し、自動スクロール機能を追加
- E2Eテスト（システムテスト）を追加：CI環境でのヘッドレスブラウザテスト

## データベース構造
- users: ユーザー情報（profit_ratio含む）
- materials: 材料マスタ
- material_quantities: 材料の単位と価格
- products: 製品マスタ
- product_ingredients: 製品の材料構成
- units: 単位マスタ

## 実装時の注意事項

- テストが全て通るかを確認すること。
- lintが通ることを確認すること。通らない場合、修正すること。
  - lintはrubocopを使っています。特に以下の指摘は、lintで指摘される以前に対応してください。
    - Layout/TrailingWhitespace; avoid trailing whitespace
    - Layout/TrailingEmptyLines; final_newline
    - Style/StringLiterals; use double_quotes
- コミットメッセージは英語で記述すること。
