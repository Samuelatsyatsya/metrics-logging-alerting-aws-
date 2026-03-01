data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  ecs_service_arn = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}"
}

data "aws_iam_policy_document" "jenkins_ecs_deploy" {
  statement {
    sid    = "EcsServiceReadAndUpdate"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = [local.ecs_service_arn]
  }

  statement {
    sid    = "EcsTaskDefinitionReadAndRegister"
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "PassTaskRolesToEcs"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = var.pass_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "jenkins_ecs_deploy" {
  name        = "${var.project_name}-jenkins-ecs-deploy"
  description = "Least-privilege ECS deployment policy for Jenkins pipeline"
  policy      = data.aws_iam_policy_document.jenkins_ecs_deploy.json
  tags        = var.tags
}

resource "aws_iam_user_policy_attachment" "jenkins_ecs_deploy" {
  count = var.principal_type == "user" ? 1 : 0

  user       = var.principal_name
  policy_arn = aws_iam_policy.jenkins_ecs_deploy.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_ecs_deploy" {
  count = var.principal_type == "role" ? 1 : 0

  role       = var.principal_name
  policy_arn = aws_iam_policy.jenkins_ecs_deploy.arn
}
