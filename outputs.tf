output "google_container_cluster" {
    value = google_container_cluster.default
}

# output "google_client_config" {
#     value = data.google_client_config.default
# }

# output "scdf_data" {
#     value = data.kubernetes_service.scdf_data
# }

# output "nginx_ingress" {
#     value = data.kubernetes_service.nginx_ingress_data
# }

# output "master_version" {
#     value = local.nginx_ingress_ip
# }

# http --server.port=3030 --allowed-origins=http://locust.storm200825.tk. | transform --expression='payload.valueOf((815.303*303.815)/303)' | log