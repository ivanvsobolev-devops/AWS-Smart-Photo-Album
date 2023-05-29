provider "aws" {
  profile = "sobolev-family"
  region = "eu-north-1"

}

terraform {
  backend "s3" {
    profile = "sobolev-family"
    region = "eu-north-1"
    bucket = "sobolev-family-photoalbum-terraform-state"
    key = "terraform.tfstate"

  }
  required_providers {
    aws ={
      version = "~>4.0"
    }
  }
}
