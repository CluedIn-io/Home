variable "cluedin_namespace" {
  type = string
}

variable "cluster_docker_registry_server" {
  type = string
}

variable "cluster_docker_secret_name" {
  type = string
}

variable "cluster_nuget_secret_name" {
  type = string
}

variable "cluster_ca_certificate_secret_name" {
  type = string
}

variable "cluster_tls_certificate_secret_name" {
  type = string
}

variable "cluster_docker_username" {
  type = string
}

variable "cluster_docker_password" {
  type = string
}

variable "cluster_nuget_token" {
  type = string
}

variable "environment_path" {
  type = string
}

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  kubeconfig_path = "${var.environment_path}/kubeconfig"
  cakey_path = "${var.environment_path}/certs/ca.key"
  cacrt_path = "${var.environment_path}/certs/ca.crt"
  cakey_exists = fileexists(local.cakey_path)
  cacrt_exists = fileexists(local.cacrt_path)
  tlskey_path = "${var.environment_path}/certs/tls.key"
  tlscrt_path = "${var.environment_path}/certs/tls.crt"
  tlskey_exists = fileexists(local.tlskey_path)
  tlscrt_exists = fileexists(local.tlscrt_path)
  caCrtOnly = local.cacrt_exists && !local.cakey_exists
}

# Provider configuration

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

resource "kubernetes_namespace" "cluedin_namespace" {
  metadata {
    name = var.cluedin_namespace
  }
}

resource "kubernetes_secret" "docker_registry_access" {

  depends_on = [kubernetes_namespace.cluedin_namespace]

  metadata {
    name = var.cluster_docker_secret_name
    namespace = var.cluedin_namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = <<DOCKER
  {
    "auths": {
      "${var.cluster_docker_registry_server}": {
        "auth": "${base64encode("${var.cluster_docker_username}:${var.cluster_docker_password}")}"
      }
    }
  }
  DOCKER
  }
}

resource "kubernetes_secret" "nuget_config" {

  depends_on = [kubernetes_namespace.cluedin_namespace]

  metadata {
    name = var.cluster_nuget_secret_name
    namespace = var.cluedin_namespace
  }
  data = {
    "nuget.config" = templatefile("${path.module}/nuget.tmpl", { pat=var.cluster_nuget_token })
  }
}

#CA Certificate Secret

resource "kubernetes_secret" "local_ca_certificate" {

  metadata {
    name = var.cluster_ca_certificate_secret_name
    namespace = var.cluedin_namespace
  }
  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = file(local.cacrt_path)
    "tls.key" = file(local.cakey_path)
  }

  count = local.cakey_exists && local.cacrt_exists ? 1 : 0
}

# TLS Certificate

resource "kubernetes_secret" "local_tls_certificate" {

  metadata {
    name = var.cluster_tls_certificate_secret_name
    namespace = var.cluedin_namespace
  }
  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = file(local.tlscrt_path)
    "tls.key" = file(local.tlskey_path)
  }

  count = !local.cacrt_exists && !local.cakey_exists && local.tlskey_exists && local.tlscrt_exists ? 1 : 0
}

# TLS + CA Certificate

resource "kubernetes_secret" "local_tls_and_ca_certificate" {

  metadata {
    name = var.cluster_tls_certificate_secret_name
    namespace = var.cluedin_namespace
  }
  type = "kubernetes.io/tls"

  data = {
    "ca.crt"  = file(local.cacrt_path)
    "tls.crt" = file(local.tlscrt_path)
    "tls.key" = file(local.tlskey_path)
  }

  count = local.caCrtOnly && local.tlskey_exists && local.tlscrt_exists ? 1 : 0
}