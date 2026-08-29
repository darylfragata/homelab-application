terraform {
  backend "s3" {
    bucket       = "df-iac-tfstate"
    key          = "app/prod/application.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
