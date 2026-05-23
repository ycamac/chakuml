# Skill: ngrok Dev Tunnel

## Start

```bash
ngrok start --config tools/ngrok.yml backend
```

## Update frontend

Copy the ngrok HTTPS URL and set in Vercel dashboard:
```
API_URL=https://xxxx.ngrok-free.app
```

## Notes
- Each ngrok restart generates a new URL → update Vercel env and redeploy.
- Verify: `curl https://xxxx.ngrok-free.app/health`
