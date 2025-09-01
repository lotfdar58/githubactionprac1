resource "aws_lambda_function" "my_lambda" {
  function_name = "my-local-lambda"
  package_type  = "Image"

  image_uri = "localhost:5000/my-app:latest"

  role = "arn:aws:iam::000000000000:role/lambda-ex"
}
