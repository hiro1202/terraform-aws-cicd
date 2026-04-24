resource "aws_codedeploy_app" "ecs" {
  name             = local.codedeploy_app_name
  compute_platform = "ECS"

  tags = local.common_tags
}

resource "aws_codedeploy_deployment_group" "ecs" {
  app_name               = aws_codedeploy_app.ecs.name
  deployment_group_name  = local.codedeploy_deployment_group_name
  deployment_config_name = var.deployment_config_name
  service_role_arn       = aws_iam_role.codedeploy.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = var.deployment_ready_wait_time_in_minutes > 0 ? "STOP_DEPLOYMENT" : "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = var.deployment_ready_wait_time_in_minutes
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }

      dynamic "test_traffic_route" {
        for_each = var.test_listener_arn == null ? [] : [var.test_listener_arn]
        content {
          listener_arns = [test_traffic_route.value]
        }
      }

      target_group {
        name = var.blue_target_group_name
      }

      target_group {
        name = var.green_target_group_name
      }
    }
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy_attachment.codedeploy_ecs]
}
