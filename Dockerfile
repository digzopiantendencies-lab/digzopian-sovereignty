# Minimal Dockerfile that uses the official SearXNG image as base
FROM searxng/searxng:latest

# Expose default port
EXPOSE 8080

# No additional layers by default; this Dockerfile allows CI/local build to re-tag the upstream image
CMD ["/bin/sh", "-c", "exec /usr/local/bin/gunicorn searx.webapp:app -b 0.0.0.0:8080"]
