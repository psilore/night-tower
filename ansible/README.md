# Ansible

Automation and configuration management for the **Night-Tower** homelab infrastructure.

---

## Prerequisites

```bash
# Ansible (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install ansible

# Required collections
ansible-galaxy collection install community.docker community.general
```

---

## Quick Start

### 1. Clone and navigate

```bash
git clone https://github.com/psilore/night-tower.git
cd night-tower/ansible
```

### 2. Create your inventory

```bash
cp inventory.yaml.example inventory.yaml
```

Edit `inventory.yaml` and fill in your real IPs and usernames. This file is **gitignored** and will never be committed.

### 3. Set up Ansible Vault

Create a password file for encrypting/decrypting secrets:

```bash
echo 'your-vault-password' > .vault-password
chmod 600 .vault-password
```

Edit the vault with your real secrets:

```bash
ansible-vault encrypt group_vars/vault.yml
ansible-vault edit group_vars/vault.yml
```

> [!IMPORTANT]
> `.vault-password` is gitignored. Never commit this file. Store your vault password in a password manager.

### 4. Run the site playbook

```bash
ansible-playbook -i inventory.yaml site.yml -K
```

---

## Secrets Management

This project uses **Ansible Vault** to keep sensitive data encrypted at rest in the public repository.

**Common vault commands:**

```bash
# Encrypt the vault file (first time)
ansible-vault encrypt group_vars/vault.yml

# Edit secrets
ansible-vault edit group_vars/vault.yml

# View secrets (read-only)
ansible-vault view group_vars/vault.yml

# Re-key (change vault password)
ansible-vault rekey group_vars/vault.yml
```

---

## Inventory

The inventory template (`inventory.yaml.example`) defines:

| Host         | Purpose                       |
| :----------- | :---------------------------- |
| `proxmox-01` | Bare-metal Proxmox hypervisor |
| `docker-vm`  | Docker services VM            |

**Host Groups:**

- `all` — Both hosts
- `docker_vms` — Docker VM only

---

## Site Playbook

The main entry point that configures the entire stack:

```bash
ansible-playbook -i inventory.yaml site.yml -K
```

| Play                | Targets      | Role                                                     |
| :------------------ | :----------- | :------------------------------------------------------- |
| Base configuration  | `all`        | `common` — updates, packages, timezone, sudo             |
| Hardware monitoring | `proxmox-01` | `monitoring_agent` — Telegraf, lm-sensors, smartmontools |
| Docker stack        | `docker-vm`  | `docker_host` + `monitoring_stack`                       |

---

## Playbooks

All playbooks are run from the `ansible/` directory:

```bash
ansible-playbook -i inventory.yaml playbooks/<playbook>.yaml -K
```

### 🔧 System

| Playbook                     | Targets | Description                                          |
| :--------------------------- | :------ | :--------------------------------------------------- |
| `maintenance.yaml`           | `all`   | Dist-upgrade, autoclean, reboot if needed (rolling)  |
| `tailscale_maintenance.yaml` | `all`   | Ensure Tailscale is installed, running, and upgraded |

### 🐳 Docker

| Playbook                  | Targets      | Description                                          |
| :------------------------ | :----------- | :--------------------------------------------------- |
| `update_services.yaml`    | `docker_vms` | Pull and recreate all Docker Compose services        |
| `docker_maintenance.yaml` | `docker_vms` | Maintain a single service (`-e service_name=<name>`) |
| `cleanup_services.yaml`   | `docker_vms` | Prune containers, networks, dangling images, volumes |
| `list_services.yaml`      | `docker_vms` | List all service directories under `/opt/`           |

### 💾 Backups

| Playbook                    | Targets      | Description                                          |
| :-------------------------- | :----------- | :--------------------------------------------------- |
| `backup_n8n_workflows.yaml` | `docker_vms` | Deploy and run the n8n workflow backup script        |
| `prune_backups.yaml`        | `all`        | Remove old backup archives (keeps last 7 by default) |

---

## Usage Examples

```bash
# System maintenance (rolling updates)
ansible-playbook -i inventory.yaml playbooks/maintenance.yaml -K

# Update all Docker services
ansible-playbook -i inventory.yaml playbooks/update_services.yaml -K

# Maintain a single Docker service
ansible-playbook -i inventory.yaml playbooks/docker_maintenance.yaml -K -e service_name=grafana

# Tailscale upgrade and status check
ansible-playbook -i inventory.yaml playbooks/tailscale_maintenance.yaml -K

# Prune backups with custom retention
ansible-playbook -i inventory.yaml playbooks/prune_backups.yaml -K -e keep_count=14

# List all deployed services on the Docker VM
ansible-playbook -i inventory.yaml playbooks/list_services.yaml -K
```

---

## Roles

| Role               | Purpose                                                                               |
| :----------------- | :------------------------------------------------------------------------------------ |
| `common`           | Base system config: apt updates, essential packages, timezone, NTP, passwordless sudo |
| `monitoring_agent` | InfluxData repo + GPG key, Telegraf, lm-sensors, smartmontools                        |
| `monitoring_stack` | Git pull + Docker Compose deployment for the monitoring stack                         |
| `docker_host`      | Ensures Docker engine is installed and running                                        |

---

## Directory Structure

```
ansible/
├── ansible.cfg
├── inventory.yaml.example         # Template (committed)
├── inventory.yaml                 # Real inventory (gitignored)
├── site.yml                       # Main entry point
├── group_vars/
│   ├── all.yml                    # Non-sensitive defaults
│   └── vault.yml                  # Encrypted secrets (ansible-vault)
├── playbooks/
│   ├── backup_n8n_workflows.yaml
│   ├── cleanup_services.yaml
│   ├── docker_maintenance.yaml
│   ├── list_services.yaml
│   ├── maintenance.yaml
│   ├── prune_backups.yaml
│   ├── tailscale_maintenance.yaml
│   └── update_services.yaml
└── roles/
    ├── common/
    ├── docker_host/
    ├── monitoring_agent/
    └── monitoring_stack/
```
