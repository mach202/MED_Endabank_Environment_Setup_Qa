module "networking" {
    source = "./src/modules/network"

    project_id = "medellin-med"
    network_name = "medellin-med-endabank-vpc-qa"
    auto_create_subnetworks = false
    delete_default_routes_on_create = false
    description = "VPC for QA Endabank bech project"
    
}

module "management-subnet" {
    source = "./src/modules/subnet"

    project_id = "medellin-med"
    subnet_name = "medellin-med-endabank-management-subnet-qa"
    subnet_cidr_range = "10.0.2.0/24"
    network_name = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"

    depends_on = [module.networking]

}

module "kubernetes-subnet" {
    source = "./src/modules/subnet"

    project_id = "medellin-med"
    subnet_name = "medellin-med-endabank-backend-subnet-qa"
    subnet_cidr_range = "10.0.3.0/24"
    network_name = module.networking.network-name
    region = "us-central1"
    private_ip_google_access = "false"

    depends_on = [module.networking]
    
}

module "ssh-endbank-rule" {
    source = "./src/modules/firewall_rules"

    fw_name = "medellin-med-endabank-ssh-rule-qa"
    network = module.networking.network-name
    description = "allow http and https traffic"
    source_ranges = ["0.0.0.0/0"]
    protocol = "tcp"
    ports = ["22", "80", "443"]
    target_tags = ["http-server", "https-server"]
    
    depends_on = [module.networking]
    
}

module "jenkins-endbank-rule" {
    source = "./src/modules/firewall_rules"

    fw_name = "medellin-med-endabank-jenkins-rule-qa"
    network = module.networking.network-name
    description = "allow jenkins port"
    source_ranges = ["0.0.0.0/0"]
    protocol = "tcp"
    ports = ["8080"]
    target_tags = ["http-server", "https-server","jumpbox-host"]
    depends_on = [module.networking]
    
}

module "kubeadm-endabank-rule" {
    source = "./src/modules/firewall_rules"

    fw_name = "medellin-med-endabank-backend-rule-qa"
    network = module.networking.network-name
    description = "allow Backend ports"
    source_ranges = ["0.0.0.0/0"]
    protocol = "tcp"
    ports = ["8080","25","465","587","2525","8081"]
    target_tags = ["backend"]
    depends_on = [module.networking]

  
}
module "cloud-nat" {
    source = "./src/modules/nat"

    router_name = "medellin-med-endabank-router-qa"
    subnet_region = module.kubernetes-subnet.subnet-region
    network_id = module.networking.network-id

    
    nat_name = "medellin-med-endabank-nat-qa"
    source_subnet_id = module.kubernetes-subnet.subnet-id

    depends_on = [module.kubernetes-subnet]
    
}


module "kubernetes-nodes" {
    source = "./src/modules/compute_engine_private"

    count = 1
    instance_name = count.index == 0 ? "medellin-med-endabank-backend-qa" : "medellin-med-endabank-backend-qa-${count.index}"
    instance_zone = "us-central1-a"
    tags = ["http-server", "https-server", "backend"]
    can_ip_forward = true
    instance_type = "e2-medium"
    allow_stopping_for_update = true
    

    instance_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    instance_size = 15
    #instance_image ="debian-10-buster-v20220118"

    subnetwork = module.kubernetes-subnet.subnet-id

    #script_instances = count.index == 0? "install-kubernetes-master.sh" : "install-kubernetes-worker.sh"

    depends_on = [module.kubernetes-subnet]

    
}

module "ci-cd-jumbox-host" {
    source = "./src/modules/compute_engine_public"

    instance_name = "medellin-med-endabank-ci-cd-jumbox-host-qa"
    instance_zone = "us-central1-a"
    tags = ["http-server", "https-server", "jumpbox-host"]
    instance_type = "e2-medium"
    allow_stopping_for_update = true
    
    
    instance_image = "ubuntu-os-cloud/ubuntu-2004-lts" 
    instance_size = 40

    #instance_image = "debian-10-buster-v20220118"

    subnetwork = module.management-subnet.subnet-id

    depends_on = [module.management-subnet]

    script = "install-puppet.sh"
}

module "frontend_bucket" {
    source = "./src/modules/cloud_storage"
    
    bucket_name             = "medellin-med-endabank-frontend-qa"
    project_id              = "Medellin-MED"
    bucket_region           = "us-central1"
    bucket_force_destroy    = true

    uniform_bucket_level_access = true

    bucket_main_page_suffix = "index.html"
    bucket_not_page_found   = "404.html"
  
    bucket_origin          = ["http://med-endabank-frontend-qa.com"]
    bucket_method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    bucket_response_header = ["*"]
    bucket_max_age_seconds = 3600
}

/*
module "database" {   #database module
    
    #source = "./src/modules/sql_services"
    #private_network_name = module.networking.network-name
    #routing_mode = "REGIONAL"
    


    source = "./src/modules/sql_services"
    
    private_ip_name = "database-private-connenction-qa"
    purpose = "VPC_PEERING"
    address_type = "INTERNAL"
    private_ip_address_version = "IPV4"
    prefix_length = 20
    private_network_name_ip_address = module.networking.network-self-link #network-name

    network_name = module.networking.network-self-link # .network-name
    service = "servicenetworking.googleapis.com"
    reserved_peering_ranges = module.database.reserved-peering-ranges

    database_name = "medellin-med-endabank-database-Qa"
    database_instance =  module.database.database-name #module.database.database-name

    database_instance_name = "medellin-med-endabank-database-primary-Qa"
    database_region = var.region
    database_version = "MYSQL_5_7" #"POSTGRES_13"
    deletion_protection = false
    depends_on_database = [module.database.depends-on-database]#[google_service_networking_connection.private_vpc_connection]
    database_tier = "db-g1-small"
    availability_type = "REGIONAL"
    disk_size = 10 #10 GB DISK SIZE
    database_backup = true
    database_binary_log_enabled = true
    ipv4_enabled = false
    private_network_instance = module.networking.network-self-link

    database_user_name = var.db_user#"root"
    database_instance_credentials = module.database.database-name #revisar
    database_password = var.db_password#"admin" #revisar sensitive variables
}
*/


module "database" {   #database module
    
    #source = "./src/modules/sql_services"
    #private_network_name = module.networking.network-name
    #routing_mode = "REGIONAL"
    


    source = "./src/modules/sql_services"
    
    private_ip_name = "database-private-connenction-qa"
    purpose = "VPC_PEERING"
    address_type = "INTERNAL"
    private_ip_address_version = "IPV4"
    prefix_length = 20
    private_network_name_ip_address = module.networking.network-self-link #network-name

    network_name = module.networking.network-self-link # .network-name
    service = "servicenetworking.googleapis.com"
    reserved_peering_ranges = module.database.reserved-peering-ranges

    database_name = "medellin-med-endabank-database-postgres-qa1" 
    database_instance =  module.database.database-name #module.database.database-name

    database_instance_name = "medellin-med-endabank-database-primary-postgres-qa1"
    database_region = var.region
    database_version = "POSTGRES_13"
    deletion_protection = false
    depends_on_database = [module.database.depends-on-database]#[google_service_networking_connection.private_vpc_connection]
    database_tier = "db-g1-small"
    availability_type = "REGIONAL"
    disk_size = 10 #10 GB DISK SIZE
    database_backup = true
    ipv4_enabled = false
    private_network_instance = module.networking.network-self-link

    database_user_name = var.db_user#"root"
    database_instance_credentials = module.database.database-name #revisar
    database_password = var.db_password#"admin" #revisar sensitive variables
}






