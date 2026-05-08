# ── IAM Role for Lambda ────────────────────────────────────────────────────
# Lambda assumes this role at runtime; it grants the minimum permissions needed.
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Allows Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ── Lambda Source Package ──────────────────────────────────────────────────
# The archive provider creates a ZIP from the inline Node.js source so that
# no external files or build steps are required.
data "archive_file" "compliance_check" {
  type        = "zip"
  output_path = "${path.module}/compliance_check.zip"

  source {
    filename = "index.js"
    content  = <<-JS
      /**
       * Compliance Check Lambda
       *
       * Simulates role-based access control for an EHR system.
       *
       * Input event:
       *   { "role": "doctor" }
       *
       * Response:
       *   { "decision": "ALLOW" | "DENY", "message": "..." }
       */
      exports.handler = async (event) => {
        const PERMITTED_ROLES = ["doctor", "nurse", "admin"];

        // Normalise to lowercase so role matching is case-insensitive
        const role = (event.role || "").toLowerCase().trim();

        if (PERMITTED_ROLES.includes(role)) {
          return {
            statusCode: 200,
            decision: "ALLOW",
            message: `Role '$${role}' is authorised to access EHR data.`
          };
        }

        return {
          statusCode: 403,
          decision: "DENY",
          message: `Role '$${role}' is NOT authorised to access EHR data.`
        };
      };
    JS
  }
}

# ── Lambda Function ────────────────────────────────────────────────────────
# Invoked to check whether a given user role should be allowed to access EHR
# data. In a real system this would query Cognito groups or an ABAC policy store.
resource "aws_lambda_function" "compliance_check" {
  function_name    = "${var.project_name}-compliance-check"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.compliance_check.output_path
  source_code_hash = data.archive_file.compliance_check.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
    }
  }

  tags = { Name = "${var.project_name}-compliance-check" }
}
