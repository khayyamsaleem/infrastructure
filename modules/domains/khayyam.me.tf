variable "target_ip" {}

resource "digitalocean_domain" "khayyam_me" {
  name = "khayyam.me"
}

resource "digitalocean_record" "khayyam_me" {
  domain = digitalocean_domain.khayyam_me.name
  name   = "@"
  type   = "A"
  value  = var.target_ip
}

output "khayyam_me_urn" {
  description = "run for khayyam.me"
  value       = digitalocean_domain.khayyam_me.urn
}