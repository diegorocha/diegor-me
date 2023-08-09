locals {
  roles = [
    aws_iam_policy.dynamo_policy.arn,
  ]
}

resource "aws_iam_policy" "dynamo_policy" {
  name        = "${local.app_name}_dynamo_policy"
  path        = "/"
  description = "Policy para consulta, inclusão e alteração de dados no dynamodb do ${local.app_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListAndDescribe"
        Effect = "Allow"
        Action = [
          "dynamodb:List*",
          "dynamodb:DescribeReservedCapacity*",
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTimeToLive",
        ]
        Resource = aws_dynamodb_table.short_url.arn
      },
      {
        Sid    = "Table"
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGet*",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWrite*",
          "dynamodb:CreateTable",
          "dynamodb:Update*",
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.short_url.arn
      }
    ]
  })
}

output "roles" {
  value = local.roles
}
