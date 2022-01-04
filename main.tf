terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.16.0"
    }
  }
}
provider "digitalocean" {
  token = var.do_api_token
}

resource "digitalocean_droplet" "gitlab_runner" {
  image  = data.digitalocean_droplet_snapshot.web-snapshot.id
  name   = var.runner_name
  region = var.cloud_region
  size   = var.droplet_size
  tags   = ["gitlab"]
  #private_networking = true
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.id]
  #user_data = data.ignition_config.coreos_runner_ign.rendered
  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.pvt_key)
  }
  provisioner "file" {
    content     = <<-EOF
      [Service]
      Type=simple
      Restart=always
      RestartSec=30
      ExecStart=/usr/bin/docker run --rm --name gitlab-runner  \
        -v /home/core/gitlab-runner:/etc/gitlab-runner         \
        -v /var/run/docker.sock:/var/run/docker.sock           \
        gitlab/gitlab-runner:latest

      [Install]
      WantedBy=multi-user.target
      EOF
    destination = "/etc/systemd/system/gitlab-runner.service"
  }
  provisioner "file" {
    content     = <<-EOF
      [Unit]
      Before=gitlab-runner.service
      ConditionPathExists=!/home/core/gitlab-runner/config.toml
      [Service]
      Type=simple
      Restart=on-failure
      RestartSec=60
      ExecStart=/usr/bin/docker run --rm                 \
        -v /home/core/gitlab-runner:/etc/gitlab-runner   \
        gitlab/gitlab-runner register --non-interactive  \
        --url "${var.gitlab_address}"                    \
        --registration-token "${var.registration_token}" \
        --name "${var.runner_name}"                      \
        --executor docker                                \
        --docker-image "alpine:latest"                   \
        --locked=false                                   \
        --run-untagged=true                             \
        --docker-privileged=false                        \
        --tag-list docker

      [Install]
      WantedBy=multi-user.target
      EOF
    destination = "/etc/systemd/system/gitlab-runner-register.service"
  }
  provisioner "remote-exec" {
    inline = [
      "systemctl daemon-reload",
      "systemctl enable --now gitlab-runner.service gitlab-runner-register.service",
    ]
  }
}
