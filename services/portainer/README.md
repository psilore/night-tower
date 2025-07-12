# portainer

```bash
docker run \
  -p 8000:8000 \
  -p 9000:9000 \
  -p 9443:9443 \
  --detach \
  --name=portainer-ce \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /volume1/docker/personal/portainer-ce:/data portainer/portainer-ce
```
