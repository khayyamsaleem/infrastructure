module "doks" {
  source = "./modules/doks"
}


module "k8s" {
  source = "./modules/k8s"
}


module "domains" {
  source    = "./modules/domains"
  target_ip = module.k8s.loadbalancer_ip
}

resource "digitalocean_project" "juul" {
  name        = "juul"
  description = "personal project"
  environment = "Production"
  resources = [
    module.doks.urn,
    module.domains.khayyam_me_urn
  ]
}

output "juul-nodes" {
  description = "juul nodes"
  value       = module.doks.cluster_node_droplet_ids
}

output "juul-subnet" {
  description = "juul subnet"
  value       = module.doks.cluster_subnet
}

output "juul-loadbalancer-ip" {
  description = "loadbalancer ip"
  value       = module.k8s.loadbalancer_ip
}
