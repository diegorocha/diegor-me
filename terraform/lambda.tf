locals {
  lambda_name                 = replace(local.app_name, ".", "-")
  lambda_artifact_dir         = "${path.module}/lambda"
  lambda_layer_zipfile_name   = "layer"
  python_version              = "python3.12"
  lambda_basic_execution_role = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "null_resource" "build_lambda_layer" {
  provisioner "local-exec" {
    when    = create
    command = "./${path.module}/scripts/build-zip.sh"

    environment = {
      DESTINATION_DIR = abspath(local.lambda_artifact_dir)
      MODULE_DIR      = abspath("../src")
      ZIPFILE_NAME    = local.lambda_layer_zipfile_name
    }
  }

  triggers = {
    requirements_sha1 = sha1(file("../src/requirements.txt"))
  }
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = "${local.lambda_artifact_dir}/${local.lambda_layer_zipfile_name}.zip"
  layer_name          = "${local.lambda_name}-python-dep"
  compatible_runtimes = [local.python_version]
  depends_on          = [null_resource.build_lambda_layer]

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [null_resource.build_lambda_layer]
  }
}

data "archive_file" "lambda_zip_file" {
  output_path = "${local.lambda_artifact_dir}/lambda.zip"
  source_dir  = "${path.module}/../src"
  excludes    = ["__pycache__", "*.pyc", "terraform", ".env", ".serverless", "requirements.txt"]
  type        = "zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  version = "2012-10-17"

  statement {
    sid    = "LambdaAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_${local.lambda_name}_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_roles_attach" {
  for_each = toset(concat(local.roles, [local.lambda_basic_execution_role]))

  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}

resource "aws_lambda_function" "lambda" {
  function_name    = local.lambda_name
  filename         = data.archive_file.lambda_zip_file.output_path
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  handler          = "app.handler"
  role             = aws_iam_role.lambda_role.arn
  runtime          = local.python_version
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  memory_size      = 128
  timeout          = 3

  environment {
    variables = {
      REGION        = local.aws_region
      TABLE_NAME    = aws_dynamodb_table.short_url.name
      NOT_FOUND_URL = local.not_found_url
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
