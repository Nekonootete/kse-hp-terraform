terraform {
  backend "s3" {
    bucket       = "kse-hp-tfstate"
    key          = "stg/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}