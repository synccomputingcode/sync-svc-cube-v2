resource "aws_ecr_repository" "sync_svc_cube_repo" {
  name                 = "sync-svc-cube"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "sync_svc_cube_lf_policy" {
  repository = aws_ecr_repository.sync_svc_cube_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 30 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 30
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}


data "aws_iam_policy_document" "sync_svc_cube_policy" {
  statement {
    sid    = "All Accounts in the Org can pull"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:ListImages"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = ["${var.aws_account_id}"]
    }
  }
  statement {
    sid    = "Allow push only from github actions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${module.iam_github_oidc_role.arn}"]
    }
    actions = ["ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
    "ecr:UploadLayerPart"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = ["${var.aws_account_id}"]
    }
  }
}

resource "aws_ecr_repository_policy" "sync_svc_cube_repo_policy" {
  repository = aws_ecr_repository.sync_svc_cube_repo.name
  policy     = data.aws_iam_policy_document.sync_svc_cube_policy.json
}

