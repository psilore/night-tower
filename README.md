# Homelab

![tower](/docs/images/tower.png)

## tailscaled

Services is setup with tailscale as a tailscaled docker sidecar.

Pattern: `<service-name>.<funny-name>.ts.net`

## Services

```bash
services
├── flame
│   └── README.md
├── mealie
│   ├── compose.yaml
│   └── config
│       └── mealie.json
├── n8n
│   ├── compose.yaml
│   └── README.md
├── ollama
│   └── README.md
├── pi-hole
│   └── README.md
├── portainer
│   ├── compose.yaml
│   ├── config
│   │   └── portainer.json
│   └── README.md
├── README.md
└── uptime-kuma
    └── README.md
```
