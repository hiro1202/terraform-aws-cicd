# terraform-aws-cicd

AWS CodePipeline + CodeBuild による ECS 向け CI/CD モジュール。**ECS native Blue/Green デプロイ前提**。

## このモジュールが提供するもの

```
GitHub (CodeStar Connection)
        │
        ▼
   ┌────────┐    ┌──────────┐    ┌──────────────────┐
   │ Source │ ─▶ │  Build   │ ─▶ │ Deploy (ECS)     │
   │        │    │CodeBuild │    │ provider="ECS"   │
   └────────┘    └──────────┘    └──────────────────┘
                       │                  │
                       │ docker push      │ RegisterTaskDefinition
                       ▼                  │ + UpdateService
                     ECR                  ▼
                                    ECS Service
                              (deploymentConfiguration
                                .strategy = "BLUE_GREEN")
                                       ↓
                              ECS が Blue/Green ロールアウト
                              （bake / hooks / alarms / TG切替は
                                ECS サービス側の責務）
```

- **本モジュールが管理する**: CodePipeline / CodeBuild プロジェクト / 成果物 S3 バケット / それらの IAM ロール
- **本モジュールは管理しない**: ECS クラスタ / ECS サービス / タスク定義 / ALB / ターゲットグループ / リスナールール / lifecycle hook Lambda / アラーム / ECR リポジトリ

責務分離は呼び出し側で：

| 関心 | 管理者 |
|---|---|
| Source / Build / Deploy オーケストレーション | **本モジュール** |
| ECS サービス + Blue/Green 設定（戦略・bake・hooks・alarms・listener rules・TG pair） | 別モジュール（例: `terraform-aws-ecs-service`） |
| ECR リポジトリ | 別モジュール |

## 前提

### ECS サービス側の必須設定

呼び出し側の ECS サービスに以下を設定すること：

```hcl
resource "aws_ecs_service" "app" {
  # ...
  deployment_controller {
    type = "ECS"  # CODE_DEPLOY ではない
  }

  deployment_configuration {
    strategy = "BLUE_GREEN"
    # bake_time_in_minutes, lifecycle_hooks, alarms 等はサービス側で完結
  }

  # 重要: タスク定義のリビジョンは CodePipeline が進めるため、
  # Terraform の差分検知から除外して split-brain を防ぐ。
  lifecycle {
    ignore_changes = [task_definition]
  }
}
```

### CodeBuild buildspec が出力すべき成果物

`build_output` の primary artifact として `imagedefinitions.json` を必ず出力すること（CodeDeploy 方式で必要だった `taskdef.json` / `appspec.yaml` は不要）：

```yaml
# buildspec.yml (例)
version: 0.2

phases:
  pre_build:
    commands:
      - aws ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login --username AWS --password-stdin "$IMAGE_REPO_URL"
  build:
    commands:
      - docker build -t "$IMAGE_REPO_URL:$IMAGE_TAG" .
      - docker push "$IMAGE_REPO_URL:$IMAGE_TAG"
  post_build:
    commands:
      - printf '[{"name":"%s","imageUri":"%s"}]' "$CONTAINER_NAME" "$IMAGE_REPO_URL:$IMAGE_TAG" > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

モジュールが自動注入する環境変数: `AWS_ACCOUNT_ID` / `AWS_DEFAULT_REGION` / `IMAGE_REPO_URL` / `IMAGE_TAG` / `CONTAINER_NAME`。

## 使用例

```hcl
module "cicd" {
  source = "github.com/hiro1202/terraform-aws-cicd"

  name = "my-app"
  tags = {
    Environment = "prod"
    Owner       = "platform"
  }

  github_connection_arn = aws_codestarconnections_connection.github.arn
  full_repository_id    = "my-org/my-app"
  source_branch         = "main"

  ecs_cluster_name = module.ecs_cluster.name
  ecs_service_name = module.ecs_service.name
  container_name   = "app"

  # タスク定義から参照される全ロール ARN を渡す
  ecs_task_role_arns = [
    module.ecs_service.task_role_arn,
    module.ecs_service.task_execution_role_arn,
  ]

  image_repository_arn = module.ecr.repository_arn
  image_repository_url = module.ecr.repository_url
  image_tag            = "latest"
}
```

## 既知の検証事項

CodePipeline の `provider="ECS"` 標準アクション（CodeDeployToECS ではない）が、`deploymentConfiguration.strategy=BLUE_GREEN` のサービスに対して期待どおり Blue/Green ロールアウトを起動するか、AWS 公式ドキュメントには明記されていない。動作は強く示唆されているが、**初回採用時は使い捨てサービスでの実証検証を推奨**。

参考:
- [AWS: Migrating from a CodeDeploy blue/green to an Amazon ECS blue/green service deployment](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/migrate-code-deploy-to-ecs-blue-green.html)
- [AWS: CodePipeline Amazon ECS standard deploy action](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-ECS.html)
- [AWS: Amazon ECS built-in blue/green deployments (2025-07)](https://aws.amazon.com/about-aws/whats-new/2025/07/amazon-ecs-built-in-blue-green-deployments/)

## 開発

```sh
make ci   # fmt + validate + test + tflint + trivy
```
