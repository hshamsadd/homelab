provider "libvirt" {
  uri = "qemu+ssh://${var.libvirt_user}@${var.libvirt_host}/system?sshauth=privkey&keyfile=${var.ssh_private_key_path}&known_hosts_verify=ignore"
}

provider "tls" {}
provider "local" {}

#uri =  "qemu+ssh://zshamsadd@100.76.59.49/system?sshauth=privkey&keyfile=/home/zshamsadd/.ssh/github_actions_libvirt_key&known_hosts_verify=ignore"
