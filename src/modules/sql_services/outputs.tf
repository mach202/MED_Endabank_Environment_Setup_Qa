output "databse" {
    description = "database"
    value = google_sql_database.database.self_link
}

output "database-name" {
    description = "name of database"
    value = google_sql_database_instance.database_primary.name
} 

output "reserved_peering_ranges" {
    description = "Private ip network name"
    value = [google_compute_global_address.private_ip_address.name]
  
}

output "depends_on_database" {
    description = "depend connection for database "
    value = [google_service_networking_connection.private_vpc_connection]
}