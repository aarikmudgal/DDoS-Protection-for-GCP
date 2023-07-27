terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.5.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

# Configure the GCP provider with ADC
provider "google" {
  project = var.project
  region  = var.region
}

# Create an Autopilot Kubernetes cluster
resource "google_container_cluster" "my-autopilot-clus" {
  name     = var.cluster_name
  location = var.region

  network    = var.network
  subnetwork = var.subnetwork

  enable_autopilot = true
}

data "google_client_config" "current" {}

# Create a Kubernetes provider
provider "kubernetes" {
  host                   = google_container_cluster.my-autopilot-clus.endpoint
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.my-autopilot-clus.master_auth.0.cluster_ca_certificate)
}

# Create a Kubernetes deployment
resource "kubernetes_deployment" "my-deploy" {
  metadata {
    name = var.deployment_name
    labels = {
      app = var.deployment_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.deployment_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.deployment_name
        }
      }

      spec {
        container {
          name  = var.deployment_name
          image = var.image_url

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }

  depends_on = [google_container_cluster.my-autopilot-clus]
}

# Create HPA for the deployment
resource "kubectl_manifest" "hpa" {
  yaml_body = <<YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 3
  maxReplicas: 30
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
YAML
depends_on = [kubernetes_deployment.my-deploy]
}

# Create a Kubernetes service
resource "kubernetes_service" "my-service" {
  metadata {
    name = var.service_name
  }

  spec {
    selector = {
      app = kubernetes_deployment.my-deploy.metadata[0].labels.app
    }

    port {
      port        = var.service_port
      target_port = var.target_port
    }

    type = var.service_type
  }

  depends_on = [kubernetes_deployment.my-deploy]
}

# Configure the GCP provider with ADC
provider "kubectl" {
  host                   = google_container_cluster.my-autopilot-clus.endpoint
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.my-autopilot-clus.master_auth.0.cluster_ca_certificate)
  load_config_file       = false
}

# Create a Kubernetes ingress
resource "kubectl_manifest" "ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.allow-http: "true"
spec:
  rules:
      - http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: my-service
                  port:
                    number: 80
YAML
depends_on = [kubernetes_service.my-service]
}

resource "google_compute_security_policy" "security-policy" {
  name = var.policy_name
  type = var.policy_type

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }

  rule {
    action      = "deny(403)"
    priority    = "1000000"
    description = "Deny all search engine crawlers"
    match {
      expr {
        expression = "evaluateThreatIntelligence('iplist-search-engines-crawlers')"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = "1001000"
    description = "Deny all malicious IPs"
    match {
      expr {
        expression = "evaluateThreatIntelligence('iplist-known-malicious-ips')"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = "1002000"
    description = "OWASP Rule 1"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable') || evaluatePreconfiguredExpr('xss-v33-stable') || evaluatePreconfiguredExpr('lfi-v33-stable') || evaluatePreconfiguredExpr('rfi-v33-stable') || evaluatePreconfiguredExpr('rce-v33-stable')"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = "1003000"
    description = "OWASP Rule 2"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('methodenforcement-v33-stable') || evaluatePreconfiguredExpr('scannerdetection-v33-stable') || evaluatePreconfiguredExpr('protocolattack-v33-stable') || evaluatePreconfiguredExpr('php-v33-stable') || evaluatePreconfiguredExpr('sessionfixation-v33-stable')"
      }
    }
  }

  rule {
    action      = "deny(403)"
    priority    = "1004000"
    description = "OWASP Rule 3"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('java-v33-stable') || evaluatePreconfiguredExpr('nodejs-v33-stable') || evaluatePreconfiguredExpr('cve-canary')"
      }
    }
  }

  rule {
    action      = "throttle"
    priority    = "1005000"
    description = "Only allow 10req/10sec from an IP"
    match {
      expr {
        expression = "true"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"

      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = 10
        interval_sec = 10
      }
    }
  }

  rule {
    action      = "rate_based_ban"
    priority    = "1006000"
    description = "Only allow 10req/10sec from an IP after and then ban the IP for 5 minutes if it exceeds 60req/60sec"
    match {
      expr {
        expression = "true"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"

      rate_limit_threshold {
        count        = 10
        interval_sec = 10
      }

      ban_duration_sec = 300
      ban_threshold {
        count        = 60
        interval_sec = 60
      }

      enforce_on_key = "IP"
    }
  }

  rule {
    action      = "deny(403)"
    priority    = "2147483647"
    description = "deny all"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  depends_on = [kubectl_manifest.ingress]
}

# Create backend config to attach load balancer to security policy
resource "kubectl_manifest" "backend-config" {
  yaml_body = <<YAML
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backend-config
spec:
  securityPolicy:
    name: my-policy
  sessionAffinity:
    affinityType: "GENERATED_COOKIE"
    affinityCookieTtlSec: 0
YAML
depends_on = [google_compute_security_policy.security-policy]
}