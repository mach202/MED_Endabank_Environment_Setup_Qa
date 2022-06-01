terraform {
  backend "remote"{
      hostname ="app.terraform.io"
      organization = "Medellin-Med-Endabank-qa-1"

    workspaces {
      name = "MED_Endabank_Environment_Setup_Qa"
    }
  }
}