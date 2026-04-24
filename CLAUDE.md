# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 目的

ECS ネイティブのブルーグリーンデプロイを実現する CI/CD パイプライン（CodePipeline / CodeBuild / CodeDeploy 等）を構築する Terraform AWS モジュール。現状 `main.tf` / `variables.tf` / `outputs.tf` は空のスケルトンで、これから実装する段階。

## 開発コマンド

Makefile 経由で実行する。`tflint` と `trivy` はローカルにインストール済みである前提（未導入時は Homebrew 等で入れる）。

- `make ci` — fmt → validate → test → tflint → trivy をまとめて実行
- `make fmt` / `make validate` / `make test` — `test` は `terraform test` を実行（`tests/*.tftest.hcl` を配置する）
- `make tflint` / `make trivy`

pre-commit（`.pre-commit-config.yaml`）で `terraform_fmt` / `terraform_validate` / `terraform_tflint` / `terraform_docs` が有効。**`README.md` は `terraform_docs` により自動生成されるため手で編集しない**。

## このモジュール固有の設計判断

- **フラット構成**。このリポジトリ自体が 1 つのモジュールで、サブモジュールは作らない
- **ECS クラスタ / サービス / タスク定義は呼び出し元が管理する。このモジュールでは作成しない**（CI/CD 配管のみを提供）
- Terraform `>= 1.0`、AWS Provider `>= 6.31.0`（`versions.tf`）
- リソース名プレフィックスに `var.name`、タグは `var.tags (map(string))` を全リソースにマージ付与
- snake_case、description 必須、ハードコード禁止、S3 は暗号化＋パブリックアクセスブロック、IAM は最小権限（ワイルドカード回避）

tflint の有効ルールは `.tflint.hcl` 参照。

## エージェントチームによる実装ワークフロー

リソース追加や大きめの変更では `.claude/skills/terraform-aws-module-creator/SKILL.md` の Plan → Implement → Review ループ（指摘ゼロまで反復、最大 5 回）に沿って進める。フェーズ指示・使用する MCP ツール・`subagent_type` は SKILL.md 側が正本。
