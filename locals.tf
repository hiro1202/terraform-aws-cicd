locals {
  common_tags = merge(var.tags, {
    Module = "terraform-aws-cicd"
  })

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
  partition  = data.aws_partition.current.partition

  artifact_bucket_name = "${var.name}-cicd-artifacts-${local.account_id}-${local.region}"

  codebuild_project_name   = "${var.name}-build"
  codebuild_log_group_name = "/aws/codebuild/${local.codebuild_project_name}"

  codedeploy_app_name              = "${var.name}-app"
  codedeploy_deployment_group_name = "${var.name}-dg"

  codepipeline_name = "${var.name}-pipeline"

  codepipeline_role_name = "${var.name}-codepipeline-role"
  codebuild_role_name    = "${var.name}-codebuild-role"
  codedeploy_role_name   = "${var.name}-codedeploy-role"

  codedeploy_config_arn = "arn:${local.partition}:codedeploy:${local.region}:${local.account_id}:deploymentconfig:${var.deployment_config_name}"
}
