# OpenCode Config

My personalized OpenCode configuration.

## Files

- **`opencode.json`** — Main OpenCode configuration file. Defines MCP servers, permissions, and settings.
- **`AGENTS.md`** — Global agent instructions (e.g., Context7 MCP usage guidelines).
- **`commands/review-pr.md`** — Custom `review-pr` command for handling PR checks and review feedback.
- **`package.json`** — Dependencies required by this config (e.g., `@opencode-ai/plugin`, `@slkiser/opencode-quota`, `@renjfk/opencode-voice`).
- **`tui.json`** — TUI-specific configuration (e.g., voice plugin).

## Setup

1. Clone this repo to your machine.
2. Symlink or copy the files into your OpenCode config directory (usually `~/.config/opencode/`):
   ```bash
   ln -s $(pwd)/opencode.json ~/.config/opencode/opencode.json
   ln -s $(pwd)/AGENTS.md ~/.config/opencode/AGENTS.md
   ln -s $(pwd)/commands ~/.config/opencode/commands
   ```
3. Update **`opencode.json`** to replace machine-specific paths with paths valid on your system.

> **Note:** The `excalidraw` MCP server in `opencode.json` contains absolute paths specific to the original machine. Update the `command` array paths (`node` binary and `mcp_excalidraw` script) to match your environment.

## Plugins

### `@slkiser/opencode-quota`

Quota, usage, and token visibility for OpenCode with zero context window pollution.

- Shows popup quota toasts after assistant responses
- Adds TUI sidebar panel with quota rows
- Provides `/quota`, `/quota_status`, and `/tokens_*` commands
- Supports providers: GitHub Copilot, OpenAI, Cursor, Anthropic, and more

After syncing this config and installing dependencies, restart OpenCode and run `/quota_status` to verify.

### `@renjfk/opencode-voice`

Speech-to-text and text-to-speech plugin for OpenCode.

- **STT**: Record voice prompts with local Whisper transcription, normalized by an LLM
- **TTS**: Hear assistant responses spoken aloud via Piper TTS
- Keybinds: `ctrl+r` to record, `ctrl+x` then `s` to speak last response, `ctrl+x` then `v` to toggle auto TTS

#### Voice Prerequisites (Linux)

The plugin requires system-level binaries that are **not** installed by `npm`:

1. **sox** — for audio recording and playback
2. **whisper-cli** — for local speech-to-text transcription
3. **piper** — for local text-to-speech synthesis
4. **Voice models** — Whisper and Piper voice model files

A convenience script is provided to automate this on Debian/Ubuntu:

```bash
./scripts/setup-voice.sh
```

> **Note:** The script builds `whisper-cli` from source and downloads models (~650 MB total). It also requires `uv` (or `pipx`) for installing Piper.

#### Voice Configuration

The `tui.json` in this repo configures the voice plugin with Anthropic as the normalization LLM. Ensure `ANTHROPIC_API_KEY` is set in your environment. You can change the endpoint/model in `tui.json` to any OpenAI-compatible API (Ollama, vLLM, etc.).

## Security

This repository is configured to **never** commit sensitive data:

- `.env` files are ignored.
- No API keys, tokens, or credentials are stored in tracked files.
- Environment variables in `opencode.json` are limited to non-sensitive values (e.g., `EXPRESS_SERVER_URL=http://localhost:3000`).

If you add MCP servers that require secrets, use environment variables or a local `.env` file (which is gitignored) rather than hardcoding values.
