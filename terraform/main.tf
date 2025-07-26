terraform {
  required_version = ">= 1.0"
  
  backend "kubernetes" {
    secret_suffix    = "state"
    namespace        = "infrastructure"
    load_config_file = true
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Deploy Prometheus Stack
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "infrastructure"
  
  set {
    name  = "grafana.enabled"
    value = "true"
  }
  
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

# Create ServiceMonitor for our application
resource "kubernetes_manifest" "app_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "hello-world"
      namespace = "applications"
    }
    spec = {
      selector = {
        matchLabels = {
          app = "hello-world"
        }
      }
      endpoints = [
        {
          port = "http"
          path = "/metrics"
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus_stack]
}

# Create Grafana Dashboard
resource "kubernetes_config_map" "grafana_dashboard" {
  metadata {
    name      = "hello-world-dashboard"
    namespace = "infrastructure"
    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "hello-world-dashboard.json" = file("${path.module}/dashboards/hello-world.json")
  }

  depends_on = [helm_release.prometheus_stack]
}
