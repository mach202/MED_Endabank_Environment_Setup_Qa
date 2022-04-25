terraform {
  backend "remote"{
      hostname ="app.terraform.io"
      organization = "DevOps-Ramp-Up-Second-Part"

    workspaces {
      name = "MED_Endabank_Environment_Setup"
    }
  }
}