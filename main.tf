module "networking" {
    source = "./src/modules/network"

    project_id = "endabank"
    name_vpc = "med-endbank-vpc"
    auto_create_subnetworks = false
    delete_default_routes_on_create = false
    description = "VPC for Endabank bech project"
    
}

module "management-subnet" {
    source = "./src/modules/subnet"

    project_id = "endabank"
    subnet_name = "management-subnet"
    subnet_cidr_range = "10.0.0.0/24"
    network = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"

}

module "kubernetes-subnet" {
    source = "./src/modules/subnet"

    project_id = "endabank"
    subnet_name = "kubernetes-subnet"
    subnet_cidr_range = "10.0.1.0/24"
    network = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"
    
}

module "ssh-endbank-rule" {
    source = "./src/modules/firewall-rules"

    
    name = "ssh-rule"
    network = module.networking.network-name
    description = "allow http and https traffic"
    source_ranges = ["0.0.0.0/24"]
    allow {
      protocol = "tcp"
      ports = ["22, 80, 443"]
    }

    target_tags = ["http, https"]
    
    depends_on = [module.networking]
    
}

module "Jenkins-endbank-rule" {
    source = "./src/modules/firewall-rules"

    
    name = "jenkins-rule"
    network = module.networking.network-name
    description = "allow http and https traffic"
    source_ranges = ["10.0.0.0/24"]
    allow {
      protocol = "tcp"
      ports = ["8080"]
    }

    target_tags = ["http, https"]
    depends_on = [module.networking]
    
}

module "cloud-nat" {
    source = "./src/modules/nat"

    router_name = "med-endabank-router"
    subnet_region = module.kubernetes-subnet.subnet-region
    network_id = module.networking.network-id

    
    nat_name = "med-endabank-nat"
    source_subnet_id = module.kubernetes-subnet.subnet-id

    depends_on = [module.kubernetes-subnet]
    
}

module "kubernetes-nodes" {
    source = "./src/modules/compute_engine_private"

    count = 3
    instance_name = count.index == 0 ? "master-node" : "worker-node-${count.index}"
    zone = "us-central1-a"
    machine_type = "e2-medium"
    allow_stopping_for_update = true

    image = "debian-10-buster-v20220118"

    #tags = ["${concat(list("${var.name}-ssh", "${var.name}"), var.node_tags)}"]

    subnetwork = module.kubernetes-subnet.subnet-id

    depends_on = [module.kubernetes-subnet]

    
}

module "ci-cd-jumbox-host" {
    source = "./src/modules/compute_engine_public"

    instance_name = "ci-cd-jumbox-host"
    zone = "us-central1-a"
    machine_type = "e2-medium"
    allow_stopping_for_update = true

    image = "debian-10-buster-v20220118"

    #tags = ["${concat(list("${var.name}-ssh", "${var.name}"), var.node_tags)}"]

    subnetwork = module.management-subnet.subnet-id

    depends_on = [module.management-subnet]

    
}