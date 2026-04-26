variable "name" {
  description = "モジュール配下リソースの名前プレフィックス。CodePipeline / CodeBuild / S3 バケット等のリソース名に使用する。"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 80
    error_message = "name は 1〜80 文字で指定してください。"
  }
}

variable "tags" {
  description = "全リソースに共通で付与するタグ。呼び出し元のタグ戦略を尊重する。"
  type        = map(string)
  default     = {}
}

variable "github_connection_arn" {
  description = "ソースステージで使用する既存の CodeStar Connections Connection の ARN。呼び出し元で作成し AVAILABLE 状態にしておくこと。"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:codestar-connections|codeconnections:[a-z0-9-]+:[0-9]{12}:connection/[a-f0-9-]+$", var.github_connection_arn))
    error_message = "github_connection_arn は codestar-connections / codeconnections のいずれかの Connection ARN 形式で指定してください。"
  }
}

variable "full_repository_id" {
  description = "ソースリポジトリの owner/repo 形式の識別子（例: my-org/my-repo）。"
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.full_repository_id))
    error_message = "full_repository_id は owner/repo 形式で指定してください。"
  }
}

variable "source_branch" {
  description = "パイプラインがトリガーされるブランチ名。"
  type        = string
  default     = "main"

  validation {
    condition     = length(var.source_branch) > 0
    error_message = "source_branch は空にできません。"
  }
}

variable "ecs_cluster_name" {
  description = "デプロイ先の ECS クラスタ名。呼び出し元で作成済みのものを指定する。"
  type        = string
}

variable "ecs_service_name" {
  description = <<-EOT
    デプロイ先の ECS サービス名。サービス側で deployment_controller = "ECS"
    かつ deployment_configuration.strategy = "BLUE_GREEN" を設定しておくこと（CodeDeploy ではない、
    ECS native Blue/Green 前提）。Blue/Green の戦略・bake time・lifecycle hooks・alarms・listener rules・
    target group pair はすべて ECS サービス側の責務であり、本モジュールの関心外。
  EOT
  type        = string
}

variable "container_name" {
  description = <<-EOT
    タスク定義内のコンテナ名。CodeBuild が出力する imagedefinitions.json
    （[{ "name": "<container_name>", "imageUri": "<ECR_URL>:<TAG>" }] 形式）の name フィールドと一致する必要がある。
    CodePipeline ECS deploy action が同名コンテナの imageUri を差し替えて新タスク定義リビジョンを登録する。
  EOT
  type        = string
}

variable "ecs_task_role_arns" {
  description = <<-EOT
    タスク定義内で参照される ECS タスク実行ロール・タスクロールの ARN リスト。
    CodePipeline が ecs:RegisterTaskDefinition を実行する際に
    iam:PassRole（PassedToService=ecs-tasks.amazonaws.com）を必要とするため、
    タスク定義から参照される全ロール ARN をここに渡すこと。
    空リストの場合は PassRole 文が出力されないため、呼び出し元で別途権限を補わない限りデプロイは失敗する。
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for a in var.ecs_task_role_arns : can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+$", a))])
    error_message = "ecs_task_role_arns は IAM Role ARN 形式で指定してください。"
  }
}

variable "image_repository_arn" {
  description = "CodeBuild が push する ECR リポジトリの ARN。IAM ポリシーの Resource として最小権限化するために使用する。"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:ecr:[a-z0-9-]+:[0-9]{12}:repository/.+$", var.image_repository_arn))
    error_message = "image_repository_arn は ECR Repository ARN 形式で指定してください。"
  }
}

variable "image_repository_url" {
  description = "CodeBuild ビルド環境に IMAGE_REPO_URL として注入する ECR リポジトリ URL（例: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-app）。"
  type        = string
}

variable "image_tag" {
  description = "CodeBuild ビルド環境に IMAGE_TAG として注入するタグ名。buildspec 内で docker build/push 時に使用することを想定。"
  type        = string
  default     = "latest"
}

variable "codebuild_image" {
  description = "CodeBuild 環境コンテナイメージ。aws/codebuild/standard:7.0 等。"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "codebuild_compute_type" {
  description = "CodeBuild の compute_type。汎用 Linux コンテナ向けの BUILD_GENERAL1_SMALL / MEDIUM / LARGE / XLARGE / 2XLARGE を許容する（Lambda 系 compute_type は本モジュール対象外）。"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition     = contains(["BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE", "BUILD_GENERAL1_XLARGE", "BUILD_GENERAL1_2XLARGE"], var.codebuild_compute_type)
    error_message = "codebuild_compute_type は BUILD_GENERAL1_SMALL / MEDIUM / LARGE / XLARGE / 2XLARGE のいずれかを指定してください。"
  }
}

variable "codebuild_privileged_mode" {
  description = "CodeBuild で Docker デーモンを有効化するか。コンテナイメージをビルドする場合は true が必要。"
  type        = bool
  default     = true
}

variable "codebuild_buildspec" {
  description = <<-EOT
    インライン buildspec YAML 文字列。null の場合はソースリポジトリ内の buildspec.yml を使用する。
    どちらの場合も primary artifact（build_output）として imagedefinitions.json を必ず出力すること。
    形式は AWS CodePipeline の ECS standard deploy action が要求する
    [{ "name": "<container_name>", "imageUri": "<image_uri>" }] の JSON 配列。
    CodeDeploy 方式で必要だった taskdef.json / appspec.yaml は不要（ECS native Blue/Green では使用しない）。
  EOT
  type        = string
  default     = null
}

variable "codebuild_environment_variables" {
  description = "CodeBuild に追加で注入する環境変数。type は PLAINTEXT / PARAMETER_STORE / SECRETS_MANAGER。モジュールが自動注入する予約済み名称（AWS_ACCOUNT_ID / AWS_DEFAULT_REGION / IMAGE_REPO_URL / IMAGE_TAG / CONTAINER_NAME）は指定できない。"
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "PLAINTEXT")
  }))
  default = []

  validation {
    condition     = alltrue([for e in var.codebuild_environment_variables : contains(["PLAINTEXT", "PARAMETER_STORE", "SECRETS_MANAGER"], coalesce(e.type, "PLAINTEXT"))])
    error_message = "codebuild_environment_variables の type は PLAINTEXT / PARAMETER_STORE / SECRETS_MANAGER のいずれかを指定してください。"
  }

  validation {
    condition     = length(setintersection([for e in var.codebuild_environment_variables : e.name], ["AWS_ACCOUNT_ID", "AWS_DEFAULT_REGION", "IMAGE_REPO_URL", "IMAGE_TAG", "CONTAINER_NAME"])) == 0
    error_message = "codebuild_environment_variables には予約済み名称（AWS_ACCOUNT_ID / AWS_DEFAULT_REGION / IMAGE_REPO_URL / IMAGE_TAG / CONTAINER_NAME）を含められません。"
  }
}

variable "log_retention_in_days" {
  description = "CodeBuild CloudWatch Logs ロググループの保持日数。0 を指定すると無期限保持。"
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_in_days)
    error_message = "log_retention_in_days は CloudWatch Logs がサポートする値のいずれかを指定してください。"
  }
}

variable "force_destroy_artifact_bucket" {
  description = "terraform destroy 時に artifact バケット内のオブジェクトを強制削除するか。本番運用では false 推奨。"
  type        = bool
  default     = false
}
