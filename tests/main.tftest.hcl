test {
  parallel = true
}

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "ap-northeast-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
}

run "apply_with_mocks" {
  command = apply

  variables {
    name                  = "test-app"
    github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:123456789012:connection/aabbccdd-1122-3344-5566-77889900aabb"
    full_repository_id    = "test-org/test-repo"
    ecs_cluster_name      = "test-cluster"
    ecs_service_name      = "test-service"
    container_name        = "app"
    image_repository_arn  = "arn:aws:ecr:ap-northeast-1:123456789012:repository/test-app"
    image_repository_url  = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/test-app"
    ecs_task_role_arns = [
      "arn:aws:iam::123456789012:role/test-task-role",
      "arn:aws:iam::123456789012:role/test-task-execution-role",
    ]
  }
}
