locals {
    workspace = read_terragrunt_config(find_in_parent_folders("workspace.hcl"))
}

generate "backend" {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<-EOF
    terraform {
        backend "remote" {
            organization = "pablosspot"
            workspaces {
                prefix = "${local.workspace.locals.workspace_prefix}"
            }
        }
    }
    EOF
}

generate "provider" {
    path = "provider.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<-EOF
    variable "region" {}

    provider "aws" {
        region = var.region
    }
    EOF    
}