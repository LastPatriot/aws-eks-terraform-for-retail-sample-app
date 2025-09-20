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

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "eks-retail-sample-app-bucket"

#   lifecycle {
#     prevent_destroy = false
#   }
# }

terraform {
  backend "s3" {
    bucket = "eks-retail-sample-app-bucket"
    key    = "dev/terraform-state-file"
    # use_lockfile = true
    encrypt = true
    region  = "us-east-1"
  }
}


module "vpc" {
  source = "./modules/vpc"

  region              = var.region
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  eks_cluster_name    = var.eks_cluster_name
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
}

module "eks" {
  source = "./modules/eks"

  region           = var.region
  cluster_version  = var.cluster_version
  eks_cluster_name = var.eks_cluster_name
  node_groups      = var.node_groups
  subnet_id        = module.vpc.private_subnet_ids
  vpc_id           = module.vpc.vpc_id
}
