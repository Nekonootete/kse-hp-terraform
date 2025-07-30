terraform {
  backend "s3" {
    bucket         = "kse-hp-tfstate"
    key            = "global/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    use_lockfile   = true
  }
}