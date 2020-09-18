variable "name" {
    default = "choose-a-name"
}

variable "credentials_file" {
    default = "your-credentials.json"
}

variable "project" {
    default = "your-GCP-project-name"
}

variable "location" {
    default = "us-east1-c"
}

variable "region" {
    default = "us-east1"
}

variable "zone" {
    default = "us-east1-c"
}

variable "intial_node_count" {
    default = 1
}

variable "machine_type" {
    default = "n1-standard-1"
}