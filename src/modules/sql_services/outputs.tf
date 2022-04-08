output "databse" {
    description = "database"
    value = google_sql_database.database.self_link
}

output "database-name" {
    description = "name of database"
    value = google_sql_database_instance.database_primary.name
} 