variable "cluedin_namespace" {
  type = string
}

variable "environment_path" {
  type = string
}

variable "cluedin_organization_name" {
  type = string
}

variable "cluedin_organization_email" {
  type = string
}

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    k8s = {
      source = "banzaicloud/k8s"
    }
  }
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "k8s" {
  config_path = local.kubeconfig_path
}

resource "random_password" "org" {
  length = 16
  special = true
  min_lower = 1
  min_numeric = 1
  min_special = 1
  min_upper = 1
  override_special = "!@$#"
}

locals {

  kubeconfig_path = "${var.environment_path}/kubeconfig"

  org = {
    name = var.cluedin_organization_name
    password = random_password.org.result
    username = var.cluedin_organization_email
  }
}

resource "kubernetes_secret" "org" {

  metadata {
    name = local.org.name
    namespace = var.cluedin_namespace
  }

  data = {
    username : local.org.username
    password : local.org.password
  }
}

# Request a certificate
resource "k8s_manifest" "org_resource" {

  depends_on = [
    kubernetes_secret.org]

  content = yamlencode({
    apiVersion = "api.cluedin.com/v1"
    kind = "Organization"
    metadata = {
      name = "${local.org.name}-organization"
      namespace = var.cluedin_namespace
    }
    spec = {
      name = local.org.name
      adminUserSecret = kubernetes_secret.org.metadata.0.name
    }
  })
}

output "cluedin_org_password" {
  value = local.org.password
  sensitive = true
}