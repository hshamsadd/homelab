Ansible ownership
Your final Ansible responsibilities are:

Linux package installation
users and groups
SSH configuration
Vault SSH CA trust
Tailscale installation
Docker/container runtime installation
K3s server installation
K3s agent installation
K3s configuration
systemd services
host-level hardening
OS updates

Do not commit passwords or tokens inside group_vars or host_vars. Those files contain only ordinary configuration and Vault paths.
