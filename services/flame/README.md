# Flame

## Scripts

```bash
docker run -d \
   --name=flame \
   --publish 5210:5005 \
   --volume /volume1/docker/viggo/flame:/app/data \
   --volume /var/run/docker.sock:/var/run/docker.sock \
   --env PASSWORD=<PASSWORD> \
   --restart always \
   pawelmalak/flame
```

## Source

[Flame installation](https://github.com/pawelmalak/flame?tab=readme-ov-file#installation)