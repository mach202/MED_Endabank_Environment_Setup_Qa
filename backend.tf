terraform {
  backend "remote"{
      hostname ="app.terraform.io"
      organization = "med-endabank"

    workspaces {
      name = "cloud-environment"
    }
  }
}