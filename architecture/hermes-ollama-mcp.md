# Hermes + Ollama MCP Integration

## Purpose
This document describes the Hermes + Ollama MCP integration for the Digzopian Sovereignty project.
It exposes Ollama as an MCP completion server so Hermes can use Ollama alongside its native browser tools.

## Components
- `tools/ollama_mcp_server.py`: A minimal MCP adapter that runs on stdio and translates MCP completion requests into Ollama CLI calls.
- `~/.hermes/config.yaml`: Hermes MCP server configuration that launches the Ollama adapter.
- `gemini.md`: Project map updated with the Hermes integration handoff.

## How it works
1. Hermes starts the Ollama MCP server using the configuration in `~/.hermes/config.yaml`.
2. Hermes communicates with the adapter over stdio using the MCP protocol.
3. The adaptor forwards prompt requests to the local Ollama CLI and returns completion responses.
4. Hermes retains access to its browser task capabilities while using Ollama as the MCP LLM provider.

## Verification
1. Ensure Ollama is installed and available on the system.
2. Ensure the adapter script is reachable at `tools/ollama_mcp_server.py`.
3. Confirm `~/.hermes/config.yaml` contains the `ollama` MCP server configuration.
4. Restart Hermes and verify the new `ollama` MCP server is registered.

## Environment Variables
The adapter supports the following environment variables:
- `OLLAMA_CLI_PATH`: Full path to the `ollama` executable.
- `OLLAMA_MODEL`: The default model to run (default: `llama2:latest`).
- `OLLAMA_HOST`: Optional Ollama server host if using a remote host.
- `OLLAMA_NOHISTORY`: Set to `1`, `true`, or `yes` to disable Ollama history.

## Next step
Start the adapter and verify Hermes discovery:
```powershell
python "tools\ollama_mcp_server.py"
```
Then restart Hermes and confirm the `ollama` MCP server is available.
