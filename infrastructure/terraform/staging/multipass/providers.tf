terraform {
  required_version = ">=1.0"

  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "1.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }
  }
}