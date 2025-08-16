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

   ```bash
   playbooks
   ├── cleanup_services.yaml
   ├── list_services.yaml
   └── update_services.yaml
   ```
