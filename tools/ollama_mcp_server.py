import json
import os
import shlex
import subprocess

import anyio
import mcp.types as types
from mcp.server import Server
from mcp.server.models import InitializationOptions
from mcp.server.stdio import stdio_server

OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama2:latest")
OLLAMA_CLI_PATH = os.environ.get(
    "OLLAMA_CLI_PATH",
    r"C:\Users\steve_ccgjwyi\AppData\Local\Programs\Ollama\ollama.exe",
)
OLLAMA_HOST = os.environ.get("OLLAMA_HOST")
OLLAMA_NOHISTORY = os.environ.get("OLLAMA_NOHISTORY", "1")

server = Server(
    name="ollama-mcp",
    version="0.1",
    instructions="A minimal MCP adapter that exposes Ollama completions to Hermes over stdio.",
    website_url="https://ollama.ai/",
)


def build_prompt(argument: object) -> str:
    if argument is None:
        return ""
    if isinstance(argument, str):
        return argument
    if isinstance(argument, dict):
        if "input" in argument:
            return str(argument["input"])
        if "text" in argument:
            return str(argument["text"])
        if "prompt" in argument:
            return str(argument["prompt"])
        if "messages" in argument and isinstance(argument["messages"], list):
            lines = []
            for item in argument["messages"]:
                role = item.get("role", "user")
                content = item.get("content", "")
                lines.append(f"{role}: {content}")
            return "\n".join(lines)
        return json.dumps(argument, indent=2)
    if isinstance(argument, list):
        return "\n".join(str(item) for item in argument)
    return str(argument)


def run_ollama(prompt: str) -> str:
    if not prompt:
        raise ValueError("No prompt provided to Ollama completion server.")

    command = [OLLAMA_CLI_PATH, "run", OLLAMA_MODEL, "--format", "json", "--nowordwrap", prompt]
    env = os.environ.copy()
    if OLLAMA_HOST:
        env["OLLAMA_HOST"] = OLLAMA_HOST
    if OLLAMA_NOHISTORY.lower() in {"1", "true", "yes"}:
        env["OLLAMA_NOHISTORY"] = "1"

    process = subprocess.run(
        command,
        capture_output=True,
        text=True,
        env=env,
    )

    if process.returncode != 0:
        raise RuntimeError(
            "Ollama did not complete successfully:\n"
            f"stdout={process.stdout.strip()}\n"
            f"stderr={process.stderr.strip()}"
        )

    output = process.stdout.strip()
    try:
        payload = json.loads(output)
        if isinstance(payload, dict):
            if "message" in payload:
                return str(payload["message"])
            if "choices" in payload:
                choices = payload["choices"]
                if isinstance(choices, list) and choices:
                    first = choices[0]
                    if isinstance(first, dict) and "message" in first:
                        return str(first["message"])
                    return str(first)
            if "output" in payload:
                return str(payload["output"])
        return output
    except json.JSONDecodeError:
        return output


@server.completion()
async def complete(ref: types.PromptReference | types.ResourceTemplateReference, argument: types.CompletionArgument, context: types.CompletionContext | None) -> types.Completion | None:
    prompt = build_prompt(argument)
    completion_text = await anyio.to_thread.run_sync(run_ollama, prompt)
    return types.Completion(values=[completion_text], total=1, hasMore=False)


async def main() -> None:
    initialization_options = InitializationOptions()
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, initialization_options)


if __name__ == "__main__":
    anyio.run(main)
