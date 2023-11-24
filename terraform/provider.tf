provider "aws" {
  region     = "ap-northeast-2"
  access_key = data.hcp_vault_secrets_app.aws_app.secrets.k
  secret_key = data.hcp_vault_secrets_app.aws_app.secrets.s
}


data "hcp_vault_secrets_app" "aws_app" {
  app_name = "AWS"
}

