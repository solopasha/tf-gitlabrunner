#!/usr/bin/env bash
echo -e "fastestmirror=True\nmax_parallel_downloads=20" | tee -a /etc/dnf/dnf.conf
dnf -y up
dnf -y install elrepo-release epel-release dnf-plugins-core
yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
dnf clean all
systemctl enable --now docker
