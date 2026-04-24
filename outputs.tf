output "codepipeline_name" {
  description = "作成された CodePipeline の名前。"
  value       = aws_codepipeline.pipeline.name
}

output "codepipeline_arn" {
  description = "作成された CodePipeline の ARN。"
  value       = aws_codepipeline.pipeline.arn
}

output "codebuild_project_name" {
  description = "作成された CodeBuild プロジェクトの名前。"
  value       = aws_codebuild_project.build.name
}

output "codebuild_project_arn" {
  description = "作成された CodeBuild プロジェクトの ARN。"
  value       = aws_codebuild_project.build.arn
}

output "codedeploy_app_name" {
  description = "作成された CodeDeploy アプリケーションの名前。"
  value       = aws_codedeploy_app.ecs.name
}

output "codedeploy_app_arn" {
  description = "作成された CodeDeploy アプリケーションの ARN。"
  value       = aws_codedeploy_app.ecs.arn
}

output "codedeploy_deployment_group_name" {
  description = "作成された CodeDeploy デプロイメントグループの名前。"
  value       = aws_codedeploy_deployment_group.ecs.deployment_group_name
}

output "codedeploy_deployment_group_arn" {
  description = "作成された CodeDeploy デプロイメントグループの ARN。"
  value       = aws_codedeploy_deployment_group.ecs.arn
}

output "artifact_bucket_name" {
  description = "パイプライン成果物を格納する S3 バケットの名前。"
  value       = aws_s3_bucket.artifact.bucket
}

output "artifact_bucket_arn" {
  description = "パイプライン成果物を格納する S3 バケットの ARN。"
  value       = aws_s3_bucket.artifact.arn
}

output "codebuild_log_group_name" {
  description = "CodeBuild ビルドログを出力する CloudWatch Logs ロググループ名。"
  value       = aws_cloudwatch_log_group.codebuild.name
}

output "codebuild_log_group_arn" {
  description = "CodeBuild ビルドログを出力する CloudWatch Logs ロググループの ARN。"
  value       = aws_cloudwatch_log_group.codebuild.arn
}

output "codepipeline_role_arn" {
  description = "CodePipeline サービスロールの ARN。"
  value       = aws_iam_role.codepipeline.arn
}

output "codepipeline_role_name" {
  description = "CodePipeline サービスロールの名前（aws_iam_role_policy の role 引数用）。"
  value       = aws_iam_role.codepipeline.name
}

output "codebuild_role_arn" {
  description = "CodeBuild サービスロールの ARN。呼び出し元で追加権限を付与する際に使う。"
  value       = aws_iam_role.codebuild.arn
}

output "codebuild_role_name" {
  description = "CodeBuild サービスロールの名前（aws_iam_role_policy の role 引数用）。"
  value       = aws_iam_role.codebuild.name
}

output "codedeploy_role_arn" {
  description = "CodeDeploy サービスロールの ARN。"
  value       = aws_iam_role.codedeploy.arn
}

output "codedeploy_role_name" {
  description = "CodeDeploy サービスロールの名前（aws_iam_role_policy の role 引数用）。"
  value       = aws_iam_role.codedeploy.name
}
