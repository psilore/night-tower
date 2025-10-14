# Creating an Ansible inventory.yaml from 1Password

This guide explains how to generate an Ansible `inventory.yaml` file
using server credentials stored in 1Password, with the following format:

```yaml
all:
  hosts:
    <hostlabel>:
      ansible_host: <hostname>
      ansible_user: <ansibleuser>
```

## Prerequisites

- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/get-started/) installed and authenticated
- Access to your 1Password vault with server credentials (hostnames, IPs, SSH users, etc.)
- `jq` and `yq` (Python version) installed (for JSON/YAML parsing)

## Steps

1. **Sign in to 1Password CLI**

   ```bash
   eval $(op signin)
   ```

2. **Run the inventory generation script**

   From the project root:

   ```bash
   bash scripts/host/generate-inventory.sh
   ```

   This will create or overwrite `inventory.yaml` in the current directory.

3. **Example inventory.yaml output**

   ```yaml
   all:
     hosts:
       <host-lablel>:
         ansible_host: <service-name>.<funny-name>.ts.net # hostname or ip
         ansible_user: <user-name>
   ```

   - Each host entry is generated from 1Password items with fields:
     - `hostlabel` (used as the host key)
     - `hostname` (used as `ansible_host`)
     - `ansibleuser` (used as `ansible_user`)

4. **Reference**
   - [1Password CLI documentation](https://developer.1password.com/docs/cli/)
   - [Ansible YAML inventory documentation](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#yaml-inventory)

---

**Tip:** Always review the generated `inventory.yaml` for accuracy and security before use.
