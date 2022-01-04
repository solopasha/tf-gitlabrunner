data "digitalocean_droplet_snapshot" "web-snapshot" {
  name_regex  = "fed10-gitlab"
  region      = var.cloud_region
  most_recent = true
}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}
