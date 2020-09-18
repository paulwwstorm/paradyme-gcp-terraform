provider "google" {
    version = "3.5.0"

    credentials = file(var.credentials_file)

    project = var.project
    region = var.region
    zone = var.zone
}

resource "google_compute_network" "vpc" {
  name = "${var.name}-vpc"
  auto_create_subnetworks = "true"
}

resource "google_compute_subnetwork" "subnet" {
 name          = "${var.name}-subnet"
 ip_cidr_range = "10.10.0.0/24"
 network       = "${var.name}-vpc"
 depends_on    = [google_compute_network.vpc]
 region      = var.region
}

resource "google_compute_firewall" "firewall" {
  name    = "${var.name}-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_container_cluster" "default" {
  name               = "paul-storm"
  location           = var.location

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = true
    }
  }

  node_pool {
    node_config {
      machine_type = "e2-medium"
    }
    name       = "default-pool"
    node_count = 4

    autoscaling {
      min_node_count = 1
      max_node_count = 10
    }

  }

  network    = "${var.name}-vpc"
  subnetwork = "${var.name}-subnet"
  depends_on    = [google_compute_network.vpc]

}

data "google_client_config" "default" {}

resource "kubernetes_cluster_role_binding" "role_binding" {
  metadata {
    name = "terraform-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "617377547426-compute@developer.gserviceaccount.com"
    api_group = ""
    namespace = "default"
  }
  
}

provider "kubernetes" {
  config_context_cluster = google_container_cluster.default.name
  load_config_file       = false
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)
}

provider "kubectl" {
  config_context_cluster = google_container_cluster.default.name
  load_config_file       = false
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)
}

data "kubectl_filename_list" "manifests" {
    pattern = "./kubernetes/*.yaml"
}
 
resource "kubectl_manifest" "kubernetes_cert" {
    count = length(data.kubectl_filename_list.manifests.matches)
    yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}

provider "helm" {
  alias = "my_cluster"
  kubernetes {
    config_context_cluster = google_container_cluster.default.name
    load_config_file       = false
    host                   = "https://${google_container_cluster.default.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)
  }
}

resource "helm_release" "nginx-ingress" {
  provider      = helm.my_cluster
  name          = "nginx-ingress"
  chart         = "./nginx-ingress"

  values = [
    <<EOF
      http:
        server:      
          location: /
          auth_basic: "Prometheus"
          auth_basic_user_file: /kubernetes/nginx/.htpasswd
          proxy_pass: https://prometheus.storm200825.tk/        
    EOF
  ]
}

resource "helm_release" "spring-cloud-data-flow" {
  provider   = helm.my_cluster
  name       = "spring-cloud"
  chart         = "./spring-cloud-data-flow"

  values = [
    <<EOF
      config:
        enabled: false
      kafka:
        enabled: true
        persistence:
          size: 20Gi
      features:
        monitoring:
          enabled: true
      rabbitmq:
        enabled: false
      server:
        service:
          type: ClusterIP
      grafana:
        service:
          type: ClusterIP
        plugins:
          - digrich-bubblechart-panel
          - grafana-piechart-panel
      prometheus:
        proxy:
          service:
            type: ClusterIP
      ingress:
        enabled: true
        protocol: http
        server:
          host: "dataflow.storm200825.tk"
        grafana:
          host: "grafana.storm200825.tk"
    EOF
  ]

}

resource "kubernetes_secret" "basic-auth" {
  metadata {
        name      = "basic-auth"
        namespace = "default"
      }
  data = {
    "auth" = file("./auth")
  }
}

resource "kubernetes_ingress" "scdf_prometheus_ingress" {
  metadata {
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/auth-type" = "basic"
      "nginx.ingress.kubernetes.io/auth-secret" = "basic-auth"
      "nginx.ingress.kubernetes.io/auth-realm" = "Authentication Required - prometheus"
      "cert-manager.io/cluster-issuer" = "letsencrypt-staging"
    }
    name = "scdf-prometheus-ingress"
  }

  spec {
    backend {
      service_name = "spring-cloud-prometheus-server"
      service_port = 80
    }

    rule {
      host  = "prometheus.storm200825.tk"
      http {
        path {
          backend {
            service_name = "spring-cloud-prometheus-server"
            service_port = 80
          }

          path = "/"
        }
      }
    }

    tls {
      hosts       = ["prometheus.storm200825.tk"]
      secret_name = "tls-secret"
    }
  }
}

resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-controller"
  }

  depends_on = [helm_release.nginx-ingress]
}

locals {
  nginx_ingress_ip = "${data.kubernetes_service.nginx_ingress.load_balancer_ingress.0.ip}"
}
 
data "kubectl_filename_list" "webhooks_manifests" {
    pattern = "./webhooks/*.yaml"
}
 
resource "kubectl_manifest" "kubernetes_webhooks" {
    count = length(data.kubectl_filename_list.webhooks_manifests.matches)
    yaml_body = file(element(data.kubectl_filename_list.webhooks_manifests.matches, count.index))
}

resource "google_dns_record_set" "a" {
  name         = "*.storm200825.tk."
  managed_zone = "storm200825"
  type         = "A"
  ttl          = 300

  rrdatas = [local.nginx_ingress_ip]
}
