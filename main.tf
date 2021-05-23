provider "aws" {
  region = "ap-southeast-1"
}
module "cluster" {
  source  = "./cluster"
}
output "nodes" {
  value = module.cluster.cluster_nodes
}
provider "kubernetes" {
  host = "https://172.31.9.122:6443"
  config_path = "./kube_config.yaml"
}

resource "kubernetes_pod" "ghost_alpine" {
metadata {
name = "ghost-alpine"
}

spec {
host_network = "true"
container {
image = "ghost:alpine"
name = "ghost-alpine"
}
}
}
