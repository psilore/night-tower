# Uptime Kuma

## Scripts

```bash
docker run -d \
   --restart=always \
   -p 3001:3001 \
   -v /volume1/docker/viggo/uptime-kuma:/app/data \
   --name uptime-kuma \
   louislam/uptime-kuma:1
```
