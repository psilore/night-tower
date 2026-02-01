# Nginx Reverse Proxy & SSL Setup

Reverse proxy architecture for `example.com`.

**Goal:**
Use the Proxmox Host (`proxmox-01`) as the "secure" 🤫 (Reverse Proxy) for all services running in the Docker VM (`docker-01`).

**Architecture:**

1. **User** requests `https://example.com`
2. **DNS (Cloudflare)** points to Proxmox Host IP (`192.168.0.100`)
3. **Nginx (on Proxmox)** terminates SSL using Let's Encrypt.
4. **Nginx** proxies traffic via HTTP to the Docker VM (`192.168.0.101`).

---

## 1. Prerequisites

- **Proxmox Host**: `192.168.0.100` (Runs Nginx)
- **Docker VM**: `192.168.0.101` (Runs Containers)
- **Domain**: `example.com` managed on Cloudflare.
- **Nginx**: Installed directly on Proxmox (`apt install nginx`).

---

## 2. Certificate Management (ACME)

We use Proxmox's built-in ACME tool with the **Cloudflare DNS Plugin** to generate certificates.
**Note:** Proxmox does not natively support Wildcards easily in the UI, so we use a Multi-Domain (SAN) certificate.

### Configuration File

Certificates are defined in `/etc/pve/nodes/proxmox-01/config`.
To verify or edit domains manually:

```bash
nano /etc/pve/nodes/proxmox-01/config
```

**Required format:**

```text
acmedomain0: domain=proxmox-01.example.com,plugin=cloudflare-dns
acmedomain1: domain=homarr.example.com,plugin=cloudflare-dns
acmedomain2: domain=grafana.example.com,plugin=cloudflare-dns
```

### Renewing / Ordering Certificates

After adding a new domain to the config file above, force a renewal:

```bash
pvenode acme cert order --force
systemctl reload nginx
```

---

## 3. Nginx Configuration

Configuration files are stored in `/etc/nginx/conf.d/`.

### Main Proxmox Config (Default)

**File:** `/etc/nginx/conf.d/proxmox-proxy.conf`

- Handles `proxmox-01.example.com`
- Acts as the **default_server** (catches IP traffic and unknown domains).

```nginx
upstream proxmox {
    server 127.0.0.1:8006;
}

server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    server_name _;
    
    ssl_certificate /etc/pve/local/pveproxy-ssl.pem;
    ssl_certificate_key /etc/pve/local/pveproxy-ssl.key;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass https://proxmox;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket Support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_ssl_verify off; 
        proxy_buffering off;
        client_max_body_size 0;
    }
}
```

### Docker Service Config (Template)

**File:** `/etc/nginx/conf.d/<service-name>.conf`

- Handles specific subdomains (e.g., `homarr`, `grafana`).
- Proxies to the Docker VM IP (`192.168.0.101`).

**Template:**

```nginx
upstream <service_name> {
    server 192.168.0.101:<PORT>;
}

server {
    listen 80;
    server_name <service_name>.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name <service_name>.example.com;

    ssl_certificate /etc/pve/local/pveproxy-ssl.pem;
    ssl_certificate_key /etc/pve/local/pveproxy-ssl.key;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://<service_name>;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket Support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 4. Workflow: Adding a New Service

Example: Adding **Grafana** running on port `3000`.

### Step 1: Add DNS Record

Go to Cloudflare and add a CNAME (or use the wildcard setup):

- **Type:** CNAME
- **Name:** `grafana`
- **Target:** `proxmox-01.example.com`

### Step 2: Update Certificate

1. Edit the Proxmox config:

   ```bash
   nano /etc/pve/nodes/proxmox-01/config
   ```

2. Add the new line (increment the number):

   ```text
   acmedomainX: domain=grafana.example.com,plugin=cloudflare-dns
   ```

3. Order the cert:

   ```bash
   pvenode acme cert order --force
   ```

### Step 3: Create Nginx Config

1. Copy an existing config:

   ```bash
   cp /etc/nginx/conf.d/homarr.conf /etc/nginx/conf.d/grafana.conf
   ```

2. Edit the file (`nano /etc/nginx/conf.d/grafana.conf`):

   - Change `upstream homarr` to `upstream grafana`.
   - Change port `7575` to `3000`.
   - Change `server_name` to `grafana.example.com`.
   - Change `proxy_pass` to `http://grafana`.

### Step 4: Apply

```bash
nginx -t
systemctl reload nginx
```
