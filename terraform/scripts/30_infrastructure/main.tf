variable "cluedin_namespace" {
  type = string
}

variable "cluedin_chart_version" {
  type = string
  default = ""
}

variable "environment_path" {
  type = string
}

variable "install_timeout" {
  type = number
}

# MONITORING

variable "cluedin_domain" {
  type = string
}

variable "cluedin_monitoring_enabled" {
  type = bool
}

# ELASTICSEARCH

variable "elastic_disk_size" {
  type = string
}

variable "elastic_replicas" {
  type = number
}

# NEO4J

variable "neo4j_disk_size" {
  type = string
}

# OPENREFINE

variable "openrefine_disk_size" {
  type = string
}

variable "openrefine_image_version" {
  type = string
}

# RABBITMQ

variable "rabbitmq_disk_size" {
  type = string
}

variable "rabbitmq_username" {
  type = string
}

variable "rabbitmq_password" {
  type = string
}

# REDIS

variable "redis_disk_size" {
  type = string
}

# SQLSERVER

variable "sql_sa_password" {
  type = string
}

variable "sql_disk_data_size" {
  type = string
}

variable "sql_disk_backup_size" {
  type = string
}

variable "sql_disk_transaction_size" {
  type = string
}

variable "sql_disk_master_size" {
  type = string
}

# SEQ

variable "cluedin_seq_enabled" {
  type = bool
  default = false
}

variable "seq_disk_size" {
  type = string
}

# VALUES ADDITION

variable "cluedin_values_infrastructure" {
  default = ""
  type = string
}

variable "cluedin_install_recreate_pods" {
  type = bool
  default = false
}

locals {
  kubeconfig_path = "${var.environment_path}/kubeconfig"

  values_files = [
    var.cluedin_values_infrastructure != "" ? (fileexists(var.cluedin_values_infrastructure) ? file(var.cluedin_values_infrastructure) : "") : ""
  ]

}

# Provider configuration

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

#CLUEDIN INFRASTRUCTURE INSTALLATION

resource "helm_release" "infrastructure" {

  repository = "https://cluedin-io.github.io/CluedIn.Helm"
  chart = "cluedin-infrastructure"
  version = var.cluedin_chart_version
  name = "cluedin-infrastructure"
  namespace = var.cluedin_namespace
  dependency_update = true
  devel = true
  wait = true
  recreate_pods = var.cluedin_install_recreate_pods
  timeout = var.install_timeout

  values = compact(local.values_files)

  # ELASTICSEARCH

  set{
    name = "elasticsearch.replicas"
    value = var.elastic_replicas
  }
  
  set{
    name = "elasticsearch.clusterHealthCheckParams"
    value = "wait_for_status=yellow&timeout=1s"
  }

  set {
    name = "elasticsearch.volumeClaimTemplate.resources.requests.storage"
    value = var.elastic_disk_size
  }

  # NEO4J

  set{
    name = "neo4j.core.persistentVolume.size"
    value = var.neo4j_disk_size
  }

  # OPENREFINE

  set {
    name = "openrefine.persistence.persistentVolumeClaim.storageSize"
    value = var.openrefine_disk_size
  }

  set{
    name = "openrefine.image.tag"
    value = var.openrefine_image_version
  }

  set{
    name = "openrefine.ingress.enabled"
    value = false
  }

  # RABBITMQ

  set {
    name = "rabbitmq.persistence.size"
    value = var.rabbitmq_disk_size
  }

  set {
    name = "rabbitmq.auth.username"
    value = var.rabbitmq_username
  }

  set {
    name = "rabbitmq.auth.password"
    value = var.rabbitmq_password
  }

  # REDIS

  set {
    name = "redis.master.persistence.size"
    value = var.redis_disk_size
  }

  # SQLSERVER

  set{
    name = "mssql-linux.persistence.dataSize"
    value = var.sql_disk_data_size
  }

  set{
    name = "mssql-linux.persistence.transactionLogSize"
    value = var.sql_disk_transaction_size
  }

  set{
    name = "mssql-linux.persistence.backupSize"
    value = var.sql_disk_backup_size
  }

  set{
    name = "mssql-linux.persistence.masterSize"
    value = var.sql_disk_master_size
  }

  set{
    name = "mssql-linux.sapassword"
    value = var.sql_sa_password
  }

  # SEQ

  set {
    name = "seq.enabled"
    value = var.cluedin_seq_enabled
  }

  set {
    name = "seq.persistence.size"
    value = var.seq_disk_size
  }

  # MONITORING

  set {
    name = "global.dns.hostname"
    value = var.cluedin_domain
  }

    set {
    name = "monitoring.enabled"
    value = var.cluedin_monitoring_enabled
  }

}