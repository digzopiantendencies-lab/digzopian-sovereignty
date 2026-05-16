Tools for building and deploying SearXNG

install.ps1
- Validates and assists with installing prerequisites: Docker CLI, Buildx, creates a builder named 'cloud'.

deploy-searxng.ps1
- Builds with Docker Buildx, optionally pushes to a registry, and can run a smoke test.

Examples

Run prerequisites check (elevated PowerShell):

```powershell
Set-Location .\tools
.\install.ps1
```

Build locally and run smoke test:

```powershell
.\deploy-searxng.ps1 -ImageName searxng -Tag localtest -Run
```

Build and push to GitHub Container Registry:

```powershell
.\deploy-searxng.ps1 -ImageName searxng -Tag v1 -Registry ghcr.io/yourorg -Push
```

More automation

- Use docker-compose for local testing (mounts `tools/settings.yml`):

```powershell
# tag the previously built image to match compose default or set COMPOSE_IMAGE
docker tag searxng:localtest2 searxng:localtest
docker-compose -f tools/docker-compose.yml -f tools/docker-compose.override.yml up -d --build
```

- Push an image with credentials (script `tools/push-image.ps1`):

```powershell
.\push-image.ps1 -Image ghcr.io/yourorg/searxng:v1 -Registry ghcr.io -User <user> -Token $env:GHCR_PAT
```

CI

The GitHub Actions workflow `.github/workflows/deploy-searxng.yml` builds multi-arch and runs a smoke test after pushing. Ensure `GITHUB_TOKEN` or a PAT with package:write rights is available for GHCR pushes.