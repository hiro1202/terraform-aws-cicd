---
name: terraform-aws-module-creator
description: Terraform AWS モジュールを構築・更新する汎用スキル。計画→実装→レビューのエージェントチームで品質を担保する。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, mcp__terraform__resourceUsage, mcp__terraform__resourceArgumentDetails, mcp__terraform__listDataSources, mcp__terraform__providerDetails, mcp__terraform__providerGuides, mcp__terraform__moduleSearch, mcp__terraform__moduleDetails, mcp__aws-knowledge__aws___search_documentation, mcp__aws-knowledge__aws___read_documentation, mcp__aws-knowledge__aws___recommend
---

# Terraform AWS Module Creator

Terraform AWS モジュールをエージェントチーム体制で構築する。

## ワークフロー

```
[計画者] → [実装者] → [レビュー者] → [実装者] → [レビュー者] → ... (指摘ゼロまで繰り返す)
```

各フェーズは独立したエージェントプロセスで実行する。

---

## Phase 1: 計画（Plan Agent）

Agent ツールで `subagent_type: "Plan"` を起動する。

### 計画者への指示

```
以下の要件に基づき、Terraform AWS モジュールの実装計画を作成せよ。

【要件】
$ARGUMENTS

【計画に含めること】
1. 作成対象リソースの一覧（resource / data source）
2. 各リソースの役割と依存関係
3. ファイル構成（どのリソースをどのファイルに配置するか）
4. 変数設計（variables.tf に定義する入力変数の一覧と型）
5. 出力設計（outputs.tf に定義する出力値の一覧）
6. IAM 設計（必要なロールとポリシーの概要、最小権限）
7. セキュリティ考慮事項

【MCP ツール活用】
- mcp__terraform__resourceArgumentDetails でリソースの正確な引数を確認すること
- mcp__terraform__resourceUsage でリソースの使用例を確認すること
- mcp__aws-knowledge__aws___search_documentation で AWS ベストプラクティスを確認すること
- 推測でリソース引数を決めず、必ず MCP で確認すること

【制約】
- このリポジトリ自体が 1 つのモジュール（フラット構成、サブモジュールなし）
- ECS リソースなど呼び出し元で管理するリソースは作成しない
- Terraform >= 1.0, AWS Provider >= 6.0
- 変数名・リソース名は snake_case
- リソース名プレフィックスに var.name を使用
- タグは var.tags (map(string)) でマージ付与
- 全 variable / output に description 必須
- ハードコードを避け変数または data source で値を取得
- セキュリティ: S3 は暗号化 + パブリックアクセスブロック、IAM は最小権限
```

計画者の出力をそのまま次のフェーズに渡す。

---

## Phase 2: 実装（Implementer Agent）

Agent ツールで `subagent_type: "general-purpose"` を起動する。

### 実装者への指示

```
以下の計画に基づき、Terraform コードを実装せよ。

【計画】
{Phase 1 の計画出力をここに貼る}

【ファイル構成規約】
- main.tf        — メインリソース定義（リソースが多い場合はサービス単位で分割可: codebuild.tf 等）
- variables.tf   — 入力変数
- outputs.tf     — 出力値
- versions.tf    — required_version / required_providers（既存あれば Edit）
- data.tf        — data sources（必要な場合）
- iam.tf         — IAM リソース（必要な場合）
- locals.tf      — locals（必要な場合）

【MCP ツール活用】
- コードを書く前に mcp__terraform__resourceArgumentDetails で引数を確認すること
- 不明な点は mcp__aws-knowledge__aws___search_documentation で確認すること
- 推測でコードを書かないこと

【コード規約】
- Terraform >= 1.0, AWS Provider >= 6.0
- 変数名・リソース名は snake_case
- リソース名プレフィックスに var.name を使用
- タグは var.tags (map(string)) でマージ付与
- 全 variable / output に description 必須
- セキュリティ: S3 は暗号化 + パブリックアクセスブロック、IAM は最小権限
- 既存ファイルがある場合は上書きせず Edit で追記・修正

【検証】
- 実装完了後に terraform fmt と terraform validate を実行すること
```

---

## Phase 3: レビュー（Reviewer Agent）

Agent ツールで `subagent_type: "general-purpose"` を起動する。
レビュー者は**コードを修正しない**。指摘のみ行う。

### レビュー者への指示

```
以下の Terraform モジュールのコードレビューを行え。
コードは修正せず、指摘事項のみリストアップすること。

【レビュー対象ファイル】
リポジトリルート直下の全 .tf ファイルを Read で読むこと。

【レビュー観点】
1. リソース引数の正確性 — mcp__terraform__resourceArgumentDetails で引数が正しいか検証
2. IAM 最小権限 — 不要なワイルドカード (*) や過剰な Action がないか
3. セキュリティ — S3 暗号化、パブリックアクセスブロック、機密情報の露出
4. 変数設計 — 型・デフォルト値・description の妥当性、ハードコードの有無
5. 出力設計 — モジュール利用者に必要な値が揃っているか
6. コード規約 — snake_case、var.name プレフィックス、var.tags マージ
7. ベストプラクティス — mcp__aws-knowledge__aws___search_documentation で確認
8. terraform fmt / validate — フォーマットとバリデーションの結果

【出力形式】
指摘がある場合:
- ファイル名と行番号
- 問題の内容
- 修正案

指摘がない場合:
「指摘事項なし。レビュー完了。」とだけ出力すること。
```

---

## Phase 4: 修正（Implementer Agent に再指示）

レビューで指摘があった場合、実装者エージェントを再起動して修正させる。

### 修正者への指示

```
以下のレビュー指摘を修正せよ。

【指摘事項】
{Phase 3 のレビュー出力をここに貼る}

【ルール】
- 指摘された箇所のみ修正すること。関係ない箇所は変更しない
- MCP で引数を再確認してから修正すること
- 修正完了後に terraform fmt と terraform validate を実行すること
```

---

## ループ制御

Phase 3 → Phase 4 を繰り返す。終了条件:

- **レビュー者が「指摘事項なし」を返したら終了**
- 最大 5 ループで打ち切り（無限ループ防止）

ループ終了後、最終的な成果物のサマリーをユーザーに報告する。
