resource "aws_iam_policy" "cube_repo_ecr_policy" {
  name        = "${var.cluster_prefix}_cube_repo_ecr_policy"
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
        "Resource" : [aws_ecr_repository.cube_repo.arn, aws_ecr_repository.cubestore_repo.arn]
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

output "cube_repo_ecr_policy" {
  value = aws_iam_policy.cube_repo_ecr_policy
}