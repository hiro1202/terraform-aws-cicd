############################################
# Trust (assume role) policies
############################################

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codedeploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

############################################
# Roles
############################################

resource "aws_iam_role" "codepipeline" {
  name               = local.codepipeline_role_name
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role" "codebuild" {
  name               = local.codebuild_role_name
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role" "codedeploy" {
  name               = local.codedeploy_role_name
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume.json
  tags               = local.common_tags
}

############################################
# CodePipeline inline policy
############################################

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid    = "ArtifactBucketRW"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      aws_s3_bucket.artifact.arn,
      "${aws_s3_bucket.artifact.arn}/*",
    ]
  }

  statement {
    sid       = "UseCodeStarConnection"
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection", "codeconnections:UseConnection"]
    resources = [var.github_connection_arn]
  }

  statement {
    sid    = "InvokeCodeBuild"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:StopBuild",
    ]
    resources = [aws_codebuild_project.build.arn]
  }

  statement {
    sid    = "CodeDeployApplication"
    effect = "Allow"
    actions = [
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
    ]
    resources = [aws_codedeploy_app.ecs.arn]
  }

  statement {
    sid    = "CodeDeployDeployment"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
    ]
    resources = [aws_codedeploy_deployment_group.ecs.arn]
  }

  statement {
    sid       = "GetDeploymentConfig"
    effect    = "Allow"
    actions   = ["codedeploy:GetDeploymentConfig"]
    resources = [local.codedeploy_config_arn]
  }

  statement {
    sid       = "EcsRegisterTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid       = "PassRoleToCodeBuild"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.codebuild.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = length(var.ecs_task_role_arns) > 0 ? [1] : []
    content {
      sid       = "PassRoleToEcsTasks"
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = var.ecs_task_role_arns

      condition {
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["ecs-tasks.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "${local.codepipeline_role_name}-inline"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline.json
}

############################################
# CodeBuild inline policy
############################################

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.codebuild.arn,
      "${aws_cloudwatch_log_group.codebuild.arn}:*",
    ]
  }

  statement {
    sid    = "ArtifactBucketRW"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.artifact.arn,
      "${aws_s3_bucket.artifact.arn}/*",
    ]
  }

  statement {
    sid       = "EcrAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [var.image_repository_arn]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.codebuild_role_name}-inline"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild.json
}

############################################
# CodeDeploy (ECS) managed policy attachment
############################################

resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AWSCodeDeployRoleForECS"
}
