data "digitalocean_kubernetes_versions" "v22" {
  version_prefix = "1.22."
}

resource "digitalocean_kubernetes_cluster" "juul" {
  name         = "juul"
  region       = "nyc1"
  auto_upgrade = true
  ha           = false
  tags         = ["production"]
  version      = data.digitalocean_kubernetes_versions.v22.latest_version

  maintenance_policy {
    day        = "any"
    start_time = "06:00"
  }

  node_pool {
    auto_scale = false
    max_nodes  = 2
    min_nodes  = 2
    name       = "juul-pool"
    node_count = 2
    size       = "s-2vcpu-4gb"
    tags       = ["terraform:default-node-pool", "k8s", "juul"]
  }

  timeouts {}
}

output "cluster_node_droplet_ids" {
  description = "droplet ids for nodes in cluster"
  value = flatten([
    for node_pool in digitalocean_kubernetes_cluster.juul.node_pool : [for node in node_pool.nodes : parseint(node.droplet_id, 10)]
  ])
}

output "cluster_subnet" {
  description = "ip range for overlay network"
  value       = digitalocean_kubernetes_cluster.juul.cluster_subnet
}

output "urn" {
  description = "cluster urn"
  value       = digitalocean_kubernetes_cluster.juul.urn
}

output "cluster_info" {
  description = "reference to cluster output"
  value = digitalocean_kubernetes_cluster.juul
}