# n8n

## Scripts

```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_DATABASE=<POSTGRES_DATABASE> \
  -e DB_POSTGRESDB_HOST=<POSTGRES_HOST> \
  -e DB_POSTGRESDB_PORT=<POSTGRES_PORT> \
  -e DB_POSTGRESDB_USER=<POSTGRES_USER> \
  -e DB_POSTGRESDB_SCHEMA=<POSTGRES_SCHEMA> \
  -e DB_POSTGRESDB_PASSWORD=<POSTGRES_POSTGRES_PASSWORD> \
  -e GENERIC_TIMEZONE="Europe/Berlin" \
  -e TZ="Europe/Berlin" \
  -e DOMAIN_NAME="" \
  -e SUBDOMAIN="" \
  -e N8N_HOST=${SUBDOMAIN}.${DOMAIN_NAME} \
  -e N8N_PORT=5678 \
  -e N8N_PROTOCOL=https \
  -e NODE_ENV=production \
  -e WEBHOOK_URL=https://${SUBDOMAIN}.${DOMAIN_NAME}/ \
  -e SSL_EMAIL=user@example.com \
  -v /volume1/docker/viggo/n8n:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n
```
