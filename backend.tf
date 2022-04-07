terraform {
  backend "remote"{
      hostname = var.backend_hostname
      organization = var.backend_organization

    workspaces {
      name = var.backend_name_workspace
    }
  }
}