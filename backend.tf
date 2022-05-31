terraform {
  backend "remote"{
      hostname ="app.terraform.io"
      organization = "Medellin-Med-Endabank-qa"

    workspaces {
      name = "MED_Endabank_Environment_Setup_Qa"
    }
  }
}