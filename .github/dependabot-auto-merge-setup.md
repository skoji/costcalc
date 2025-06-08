# Dependabot自動マージのセットアップ

DependabotのPRを自動的にマージするには、以下の設定が必要です。

## 1. リポジトリ設定

GitHubリポジトリの Settings > General から以下を設定：

### Auto-merge を有効化
- "Allow auto-merge" にチェックを入れる

### Branch protection rules（mainブランチ）
Settings > Branches で main ブランチの保護ルールを設定：

- "Require a pull request before merging" を有効化
- "Require status checks to pass before merging" を有効化
  - 必須チェック項目を選択（例：CI, Lint, Test など）
- "Dismiss stale pull request approvals when new commits are pushed" を有効化
- "Include administrators" は任意

## 2. 動作の仕組み

1. Dependabotが依存関係の更新PRを作成
2. GitHub Actionsが起動し、以下を実行：
   - パッチ版・マイナー版の更新の場合のみ処理
   - PRを自動承認
   - 自動マージを有効化（squashマージ）
3. CIテストが実行される
4. 全てのチェックが通ったら自動的にマージ

## 3. 安全性

- メジャーバージョンの更新は自動マージされません
- CIテストが失敗した場合はマージされません
- Branch protection rulesで必須チェックを設定することで安全性を確保

## 4. カスタマイズ

### 自動マージの対象を変更する場合

`.github/workflows/dependabot-auto-merge.yml` の条件を編集：

```yaml
# セキュリティアップデートも含める場合
if: |
  steps.metadata.outputs.update-type == 'version-update:semver-patch' ||
  steps.metadata.outputs.update-type == 'version-update:semver-minor' ||
  steps.metadata.outputs.dependency-type == 'direct:production'
```

### マージ方法を変更する場合

```yaml
# マージコミットを使う場合
gh pr merge --auto --merge "$PR_URL"

# リベースマージを使う場合
gh pr merge --auto --rebase "$PR_URL"
```