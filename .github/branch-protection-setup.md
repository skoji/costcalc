# Branch Protection Rules 設定ガイド

## 必須ステータスチェックの設定方法

### 前提条件
- 最低1回はPRでCIが実行されている必要があります
- CIワークフローが正しく設定されていること

### このリポジトリのCIジョブ

`.github/workflows/ci.yml` で定義されているジョブ：

1. **scan_ruby** - Brakemanによるセキュリティスキャン
2. **scan_js** - JavaScriptの依存関係セキュリティチェック
3. **lint** - RuboCopによるコードスタイルチェック
4. **test** - RSpecとシステムテストの実行

### 設定手順

1. **GitHub リポジトリの Settings → Branches へ移動**

2. **main ブランチの "Edit" をクリック**

3. **以下の設定を有効化：**

   □ Require a pull request before merging
   
   □ Require status checks to pass before merging
   
   検索ボックスに以下を入力して追加：
   - `scan_ruby`
   - `scan_js`
   - `lint`
   - `test`
   
   または、ドロップダウンから選択：
   - `CI / scan_ruby`
   - `CI / scan_js`
   - `CI / lint`
   - `CI / test`

4. **追加の推奨設定：**
   
   □ Require branches to be up to date before merging
   （マージ前に最新のmainブランチとの同期を必須にする）
   
   □ Require conversation resolution before merging
   （PRのコメントが全て解決されていることを必須にする）

5. **"Save changes" をクリック**

### トラブルシューティング

**Q: ステータスチェックが選択肢に表示されない**
A: 以下を試してください：
1. 一度PRを作成してCIを実行させる
2. 手動でチェック名を入力してEnterキーを押す
3. しばらく待ってからページをリフレッシュ

**Q: 設定後、既存のPRがマージできない**
A: PRを最新のmainブランチにリベースまたはマージしてください：
```bash
git checkout your-branch
git pull origin main
git push
```

### Dependabot自動マージとの連携

上記の設定が完了すると、Dependabotの自動マージワークフローは：
1. PRを自動承認
2. 自動マージを有効化
3. 全てのステータスチェックが通るのを待機
4. 条件を満たしたら自動的にマージ

これにより、安全に依存関係の更新を自動化できます。