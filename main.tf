module "networking" {
    source = "./src/modules/network"

    project_id = "iac-challenge-345123"
    network_name = "med-endbank-vpc"
    auto_create_subnetworks = false
    delete_default_routes_on_create = false
    description = "VPC for Endabank bech project"
    
}

module "management-subnet" {
    source = "./src/modules/subnet"

    project_id = "iac-challenge-345123"
    subnet_name = "management-subnet"
    subnet_cidr_range = "10.0.0.0/24"
    network_name = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"

}

module "kubernetes-subnet" {
    source = "./src/modules/subnet"

    project_id = "iac-challenge-345123"
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
    
    bucket_name         = "med-endabank-frotend"
    project_id    = "iac-challenge-345123"
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

module "database" {
    source = "./src/modules/sql_services"
    private_network_name = module.networking.network-name
    routing_mode = "REGIONAL"
    
    private_ip_name = "database-private-connenction"
    purpose = "VPC_PEERING"
    address_type = "INTERNAL"
    prefix_length = 20
    private_network_name_ip_address = module.networking.network-name

    network_name = module.networking.network-name
    service = "servicenetworking.googleapis.com"
    reserved_peering_ranges = module.database.reserved_peering_ranges

    database_name = "med-endabank-database"
    database_instance =  module.database.database-name #module.database.database-name

    database_instance_name = "med-endabank-database_primary"
    database_region = var.region
    database_version = "POSTGRES_13"
    depends_on_database = module.database.depends_on_database#[google_service_networking_connection.private_vpc_connection]
    database_tier = "db-g1-small"
    availability_type = "REGIONAL"
    disk_size = 10 #10 GB DISK SIZE
    ipv4_enabled = false
    private_network_instance = module.networking.network.self_link

    database_user_name = "root"
    database_instance_credentials = module.database.database-name #revisar
    database_password = "admin" #revisar sensitive variables
    }
