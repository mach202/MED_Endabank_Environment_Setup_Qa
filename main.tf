module "networking" {
    source = "./src/modules/network"

    project_id = "endabank"
    network_name = "med-endbank-vpc"
    auto_create_subnetworks = false
    delete_default_routes_on_create = false
    description = "VPC for Endabank bech project"
    
}

module "management-subnet" {
    source = "./src/modules/subnet"

    project_id = "endabank"
    subnet_name = "management-subnet"
    subnet_cidr_range = "10.0.0.0/24"
    network_name = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"

}

module "kubernetes-subnet" {
    source = "./src/modules/subnet"

    project_id = "endabank"
    subnet_name = "kubernetes-subnet"
    subnet_cidr_range = "10.0.1.0/24"
    network_name = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"
    
}

module "ssh-endbank-rule" {
    source = "./src/modules/firewall_rules"

    fw_name = "ssh-rule"
    network = module.networking.network-name
    description = "allow http and https traffic"
    source_ranges = ["0.0.0.0/24"]
    protocol = "tcp"
    ports = ["22, 80, 443"]
    target_tags = ["http, https"]
    
    depends_on = [module.networking]
    
}

module "jenkins-endbank-rule" {
    source = "./src/modules/firewall_rules"

    fw_name = "jenkins-rule"
    network = module.networking.network-name
    description = "allow http and https traffic"
    source_ranges = ["10.0.0.0/24"]
    protocol = "tcp"
    ports = ["8080"]
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
    instance_zone = "us-central1-a"
    instance_type = "e2-medium"
    allow_stopping_for_update = true

    instance_image = "debian-10-buster-v20220118"

    #tags = ["${concat(list("${var.name}-ssh", "${var.name}"), var.node_tags)}"]

    subnetwork = module.kubernetes-subnet.subnet-id

    depends_on = [module.kubernetes-subnet]

    
}

module "ci-cd-jumbox-host" {
    source = "./src/modules/compute_engine_public"

    instance_name = "ci-cd-jumbox-host"
    instance_zone = "us-central1-a"
    instance_type = "e2-medium"
    allow_stopping_for_update = true

    instance_image = "debian-10-buster-v20220118"

    #tags = ["${concat(list("${var.name}-ssh", "${var.name}"), var.node_tags)}"]

    subnetwork = module.management-subnet.subnet-id

    depends_on = [module.management-subnet]

    script = "install-puppet.sh"
}

module "frontend_bucket" {
    source = "./src/modules/cloud_storage"

    project_id    = "endabank"
    bucket_name         = "med-endabank-frotend"
    bucket_region      = "us-central1 (Iowa)"
    bucket_force_destroy = true

    uniform_bucket_level_access = true

    bucket_main_page_suffix = "index.html"
    bucket_not_page_found   = "404.html"
  
    bucket_origin          = ["http://med-endabank-frontend.com"]
    bucket_method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    bucket_response_header = ["*"]
    bucket_max_age_seconds = 3600
}
