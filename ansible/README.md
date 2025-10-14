# Ansible

## Install

### For Debian/Ubuntu

```bash
sudo apt-get update && sudo apt-get install ansible
```

## Run playbook

1. Clone night-tower repo

   ```bash
   git clone https://github.com/psilore/night-tower.git
   ```

2. Navigate to ansible directory

   ```bash
   cd ansible
   ```

3. Run playbook

   ```bash
   ansible-playbook -i ansible/hosts.ini playbooks/<playbook>.yaml
   ```


    **Playbooks:**

    ```
    playbooks/
    ├── backup-n8n-workflows.yaml      # Run n8n backup script on n8n hosts
    ├── prune-backups.yaml             # Prune old backup files on backup hosts
    ├── tailscale-maintenance.yaml     # Maintain and upgrade Tailscale on tailscale hosts
    ├── cleanup_services.yaml          # Cleanup unused services
    ├── list_services.yaml             # List running services
    └── update_services.yaml           # Update services
    ```

    **Usage examples:**

    - Run n8n backup:

       ```bash
       ansible-playbook -i hosts.ini playbooks/backup-n8n-workflows.yaml
       ```

    - Prune old backups:

       ```bash
       ansible-playbook -i hosts.ini playbooks/prune-backups.yaml
       ```

      - Tailscale maintenance:

         ```bash
         ansible-playbook -i hosts.ini playbooks/tailscale-maintenance.yaml
         ```

      - Run a specific function (task) in the Tailscale playbook  
        (e.g., only upgrade Tailscale):

         ```bash
         ansible-playbook -i hosts.ini playbooks/tailscale-maintenance.yaml --start-at-task "Upgrade Tailscale to latest version"
         ```

         Or, if you add tags to tasks in the playbook, you can use:

         ```bash
         ansible-playbook -i hosts.ini playbooks/tailscale-maintenance.yaml --tags upgrade
         ```
