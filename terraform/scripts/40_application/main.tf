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

variable "kubernetes_version" {
  type = string
  default = ""
}

variable "install_timeout" {
  type = number
}

variable "cluedin_image_version" {
  type = string
}

variable "cluster_ca_certificate_secret_name" {
  type = string
}

variable "cluster_tls_certificate_secret_name" {
  type = string
}

variable "cluster_nuget_secret_name" {
  type = string
}

variable "cluedin_loopback_enabled" {
  type = bool
}

variable "cluedin_loopback_address" {
  type = string
}

variable "cluedin_loopback_ip" {
  type = string
}

variable "cluedin_domain" {
  type = string
}

variable "cluedin_image_pull_policy" {
  type = string
}

variable "cluedin_environment" {
  type = string
}

variable "cluedin_email_host" {
  default = ""
  type = string
}

variable "cluedin_email_port" {
  default = ""
  type = string
}

variable "cluedin_email_username" {
  default = ""
  type = string
}

variable "cluedin_email_password" {
  default = ""
  type = string
}

variable "cluedin_monitoring_enabled" {
  type = bool
}

variable "cluedin_monitoring_expose_admin" {
  type = bool
}

variable "cluedin_server_main_replicas" {
  type = number
}

variable "cluedin_server_processing_replicas" {
  type = number
}

variable "cluedin_server_crawling_replicas" {
  type = number
}

variable "cluedin_oauth_enabled" {
  type = bool
}

variable "cluedin_seq_enabled" {
  type = bool
}

variable "sql_sa_password" {
  type = string
}

variable "cluedin_annotation_image_version" {
  default = ""
  type = string
}

variable "cluedin_datasource_image_version" {
  default = ""
  type = string
}

variable "cluedin_gql_image_version" {
  default = ""
  type = string
}

variable "cluedin_prepare_image_version" {
  default = ""
  type = string
}

variable "cluedin_submitter_image_version" {
  default = ""
  type = string
}

variable "cluedin_ui_image_version" {
  default = ""
  type = string
}

variable "cluedin_init_neo4j_image_version" {
  default = ""
  type = string
}

variable "cluedin_init_sql_image_version" {
  default = ""
  type = string
}

variable "cluedin_nugetinstaller_image_version" {
  default = ""
  type = string
}

variable "cluedin_values_application" {
  default = ""
  type = string
}

variable "cluedin_server_components" {
  type = map(string)
}

variable "cluedin_install_recreate_pods" {
  type = bool
  default = false
}

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    k8s = {
      source = "banzaicloud/k8s"
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

  issuer = {
    "apiVersion" = "cert-manager.io/v1"
    "kind" = "Issuer"
    "metadata" = {
      "name" = "ca-issuer"
    }
    "spec" = {
      "ca" = {
        "secretName" = var.cluster_ca_certificate_secret_name
      }
    }
  }

  host_patch = {
    "cluedin" = {
      "hostAliases" = [
        {
          ip = var.cluedin_loopback_ip
          hostnames = [
            var.cluedin_loopback_address
          ]
        },
      ]
    }
  }

  ca_issuer_values = {
    "global" = {
      "ingress" = {
        "annotations" = {
          "cert-manager.io/issuer" = "ca-issuer"
        },
        "tls" = {
          secretName = var.cluster_tls_certificate_secret_name,
          hasClusterCA = true
        }
      }
    }
  }

  tls_certificate = {
    "global" = {
      "ingress" = {
        "tls" = {
          secretName = var.cluster_tls_certificate_secret_name
        }
      }
    }
  }

  tls_ca_certificate = {
    "global" = {
      "ingress" = {
        "tls" = {
          secretName = var.cluster_tls_certificate_secret_name
          hasClusterCA = true
        }
      }
    }
  }

  email_details = {
    "email" = {
      "host" = var.cluedin_email_host
      "port" = var.cluedin_email_port
      "user" = var.cluedin_email_username
      "password" = var.cluedin_email_password
    }
  }

  components = {
    "cluedin" = {
      "components" = {
        "image" = "cluedin/nuget-installer:${var.cluedin_image_version}"
        "sourcesSecretRef" = var.cluster_nuget_secret_name
        "packages" = [
          for name, version in var.cluedin_server_components:
          {
            name = name
            version = version
          }
        ]
      }
    }
  }

  values_files = [
    local.cakey_exists && local.cacrt_exists ? yamlencode(local.ca_issuer_values) : "",
    !local.cakey_exists && !local.cacrt_exists && local.tlskey_exists && local.tlscrt_exists ? yamlencode(local.tls_certificate) : "",
    local.caCrtOnly && local.tlskey_exists && local.tlscrt_exists ? yamlencode(local.tls_ca_certificate) : "",
    var.cluedin_email_username != "" && var.cluedin_email_password != "" ? yamlencode(local.email_details) : "",
    var.cluedin_loopback_enabled ? yamlencode(local.host_patch) : "",
    length(var.cluedin_server_components) > 0 ? yamlencode(local.components) : "",
    var.cluedin_values_application != "" ? (fileexists(var.cluedin_values_application) ? file(var.cluedin_values_application) : "") : ""
  ]

}

# Provider configuration

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "k8s" {
  config_path = local.kubeconfig_path
}

resource "k8s_manifest" "certificate_issuer" {

  content = yamlencode(local.issuer)
  namespace = var.cluedin_namespace
  count = local.cakey_exists && local.cacrt_exists ? 1 : 0
}

resource "helm_release" "cluedin-application" {

  repository = "https://cluedin-io.github.io/CluedIn.Helm"
  chart = "cluedin-application"
  version = var.cluedin_chart_version
  name = "cluedin-application"
  namespace = var.cluedin_namespace
  dependency_update = true
  devel = true
  wait = true
  recreate_pods = var.cluedin_install_recreate_pods
  timeout = var.install_timeout

  values = compact(local.values_files)

  # GLOBAL VALUES

  set {
    name = "global.dns.hostname"
    value = var.cluedin_domain
  }

  set {
    name = "global.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  set {
    name = "global.image.tag"
    value = var.cluedin_image_version
  }

  # MONITORING SETTINGS

  set {
    name = "monitoring.enabled"
    value = var.cluedin_monitoring_enabled
  }

  set {
    name = "monitoring.exposeAdmin"
    value = var.cluedin_monitoring_expose_admin
  }

  # CLUEDIN SERVER SETTINGS

  set {
    name = "cluedin.image.tag"
    value = var.cluedin_image_version
  }

  set {
    name = "cluedin.configuration.environment.DOTNET_Environment"
    value = var.cluedin_environment
  }

  set {
    name = "cluedin.roles.main.count"
    value = var.cluedin_server_main_replicas
  }

  set {
    name = "cluedin.roles.processing.count"
    value = var.cluedin_server_processing_replicas
  }

  set {
    name = "cluedin.roles.crawling.count"
    value = var.cluedin_server_crawling_replicas
  }

  set {
    name = "cluedin.readinessProbe.initialDelaySeconds"
    value = 30
  }

  set {
    name = "cluedin.livenessProbe.initialDelaySeconds"
    value = 30
  }

  # CLUEDIN CONTROLLER SETTINGS (Shared)

  set {
    name = "cluedincontroller.enabled"
    value = true
  }

  set {
    name = "cluedincontroller.image.tag"
    value = var.cluedin_image_version
  }

  set {
    name = "cluedincontroller.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  set {
    name = "cluedincontroller.fullnameOverride"
    value = "cluedin-controller"
  }

  # OAUTH SETTINGS

  set {
    name = "oauth.enabled"
    value = var.cluedin_oauth_enabled
  }

  # SQL SETTINGS

  set {
    name = "sqlserver.password"
    value = var.sql_sa_password
  }

  # SEQ SETTINGS

  set {
    name = "seq.enabled"
    value = var.cluedin_seq_enabled
  }

  # PREPARE SETTINGS

  set {
    name = "clean.image.tag"
    value = var.cluedin_prepare_image_version != "" ? var.cluedin_prepare_image_version : var.cluedin_image_version
  }

  set {
    name = "clean.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # ANNOTATION SETTINGS

  set {
    name = "annotation.image.tag"
    value = var.cluedin_annotation_image_version != "" ? var.cluedin_annotation_image_version : var.cluedin_image_version
  }

  set {
    name = "annotation.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # DATASOURCE SETTINGS

  set {
    name = "datasource.image.tag"
    value = var.cluedin_datasource_image_version != "" ? var.cluedin_datasource_image_version : var.cluedin_image_version
  }

  set {
    name = "datasource.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # GQL SETTINGS

  set {
    name = "gql.image.tag"
    value = var.cluedin_gql_image_version != "" ? var.cluedin_gql_image_version : var.cluedin_image_version
  }

  set {
    name = "gql.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # SUBMITTER SETTINGS

  set {
    name = "submitter.image.tag"
    value = var.cluedin_submitter_image_version != "" ? var.cluedin_submitter_image_version : var.cluedin_image_version
  }

  set {
    name = "submitter.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # UI SETTINGS

  set {
    name = "ui.image.tag"
    value = var.cluedin_ui_image_version != "" ? var.cluedin_ui_image_version : var.cluedin_image_version
  }

  set {
    name = "ui.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # INIT SQL SETTINGS

  set {
    name = "initSql.image.tag"
    value = var.cluedin_init_sql_image_version != "" ? var.cluedin_init_sql_image_version : var.cluedin_image_version
  }

  set {
    name = "initSql.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # INIT NEO4J SETTINGS

  set {
    name = "initNeo4J.image.tag"
    value = var.cluedin_init_neo4j_image_version != "" ? var.cluedin_init_neo4j_image_version : var.cluedin_image_version
  }

  set {
    name = "initNeo4J.image.pullPolicy"
    value = var.cluedin_image_pull_policy
  }

  # NUGET INSTALLER SETTINGS

  set {
    name = "cluedin.components.image.tag"
    value = var.cluedin_nugetinstaller_image_version != "" ? var.cluedin_nugetinstaller_image_version : var.cluedin_image_version
  }

  # MISC SETTINGS

  set {
    name = "global.kubeVersion"
    value = var.kubernetes_version
  }

}

output "cluedin_hostname" {
  value = var.cluedin_domain
}
