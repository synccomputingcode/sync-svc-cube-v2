resource "aws_iam_openid_connect_provider" "default" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["cf23df2207d99a74fbe169e3eba035e633b65d94"]
}

module "iam_github_oidc_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name        = "github_actions_role"
  path        = "/system/"
  description = "GitHub IAM role for GitHub actions"

  subjects = ["synccomputingcode/sync-svc-cube-v2:*"]

  policies = {
    GitHubActionsPolicy = aws_iam_policy.sync_svc_cube_ecr_policy.arn
  }
}

resource "aws_iam_policy" "sync_svc_cube_ecr_policy" {
  name        = "sync_svc_cube_ecr_policy"
  path        = "/system/"
  description = "Policy for github role to push/pull containers"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "GetAuthorizationToken",
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowPushPull",
        "Effect" : "Allow",
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource" : aws_ecr_repository.sync_svc_cube_repo.arn
      },
      {
        "Sid" : "AllowEcsServiceDeploys",
        "Effect" : "Allow",
        "Action" : [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowPassRoleToTask",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : [aws_iam_role.ecs_task_role.arn, aws_iam_role.ecs_task_execution_role.arn]
      }
    ]
  })
}
