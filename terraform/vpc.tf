module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.8"

  project = var.project
  env     = var.env
}