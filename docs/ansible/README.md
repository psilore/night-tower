# Creating an Ansible hosts.ini from 1Password

This guide explains how to generate an Ansible `hosts.ini` inventory file
using server credentials stored in 1Password, with the following format:

```shell
[host]
<host-name> ansible_user=<user>
```

## Prerequisites

- [1Password CLI (`op`)](https://developer.1password.com/docs/cli/get-started/)
   installed and authenticated
- Access to your 1Password vault with server credentials (hostnames, IPs,
   SSH users, etc.)
- `jq` installed (for JSON parsing)

## Steps

1. **Sign in to 1Password CLI**

   ```bash
   eval $(op signin)
   ```

2. **List available items**

   ```bash
   op item list --categories=server
   ```

3. **Export server details to hosts.ini**

    Use a script like the following to generate a `hosts.ini` in the format above:

    ```bash
    #!/usr/bin/env bash
    # Export all servers in a vault to hosts.ini in [host] group format

    echo "[host]" > hosts.ini

    op item list --categories=server --format=json | jq -r '.[].id' | while read -r id; do
      op item get "$id" --format=json | \
        jq -r '
          .fields as $fields |
          ($fields[] | select(.label=="hostname" or .id=="hostname").value) as $host |
          ($fields[] | select(.label=="username" or .id=="username").value) as $user |
          if $host and $user then
            "\($host) ansible_user=\($user)"
          else
            empty
          end
        ' >> hosts.ini
    done
    ```

    - This script assumes your 1Password items for servers have fields with
       `hostname` (the host name or IP) and `username` (the SSH user).
    - Adjust the field IDs if your 1Password structure is different.

4. **Example hosts.ini output**

   ```shell
   [host]
   myserver ansible_user=ubuntu
   otherserver ansible_user=admin
   ```

5. **Advanced: Grouping by tags or vaults**

    - Use `jq` to filter/group by tags or vaults if your 1Password items are
       organized that way.

6. **Reference**
   - [1Password CLI documentation](https://developer.1password.com/docs/cli/)
   - [Ansible inventory documentation](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)

---

**Tip:** Always review the generated `hosts.ini` for accuracy and security
before use.
