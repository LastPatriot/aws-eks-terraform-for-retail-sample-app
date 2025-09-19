terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "" #Give your bucket a name

  lifecycle {
    prevent_destroy = false
  }
}

# Uncomment the below only after you have created your bucket
# Because terraform cannot create your bucket and store the state in it at the same time.
# After bucket creation and uncommenting, run terraform init and terraform plan to copy the state to your remote backend.

# terraform {
#   backend "s3" {
#     bucket = "" #The name of the previously created bucket
#     key    = "dev/terraform-state-file.tfstate"
#     # use_lockfile = true
#     encrypt = true
#     region  = "us-east-1"
#   }
# }
