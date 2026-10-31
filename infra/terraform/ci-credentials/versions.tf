terraform {
  required_version = "~> 1.17"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "proyectos-personales"

    workspaces {
      name    = "supply-chain-ci-credentials"
      project = "supply-chain"
    }
  }
}


