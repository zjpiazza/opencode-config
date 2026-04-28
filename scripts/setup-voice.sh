#!/usr/bin/env bash
set -euo pipefail

echo "=== OpenCode Voice Setup (Linux) ==="
echo ""

# --- sox ---
if ! command -v rec &>/dev/null || ! command -v play &>/dev/null; then
  echo "Installing sox (requires sudo)..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq sox libsox-fmt-all
else
  echo "sox already installed."
fi

# --- whisper.cpp ---
WHISPER_DIR="${HOME}/.local/share/whisper.cpp-build"
WHISPER_BIN="${HOME}/.local/bin/whisper-cli"

if [ ! -f "$WHISPER_BIN" ]; then
  echo "Building whisper-cli from source..."
  mkdir -p "$(dirname "$WHISPER_BIN")"
  if [ ! -d "$WHISPER_DIR" ]; then
    git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git "$WHISPER_DIR"
  fi
  cd "$WHISPER_DIR"
  cmake -B build .
  cmake --build build --config Release -j"$(nproc)"
  cp build/bin/whisper-cli "$WHISPER_BIN"
  echo "whisper-cli installed to $WHISPER_BIN"
else
  echo "whisper-cli already installed."
fi

# --- whisper model ---
WHISPER_MODEL_DIR="${HOME}/.local/share/whisper-cpp"
WHISPER_MODEL="${WHISPER_MODEL_DIR}/ggml-large-v3-turbo-q5_0.bin"

if [ ! -f "$WHISPER_MODEL" ]; then
  echo "Downloading Whisper model (~550 MB)..."
  mkdir -p "$WHISPER_MODEL_DIR"
  curl -L -o "$WHISPER_MODEL" \
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin
else
  echo "Whisper model already present."
fi

# --- piper-tts ---
if ! command -v piper &>/dev/null; then
  echo "Installing piper-tts..."
  if command -v uv &>/dev/null; then
    uv tool install piper-tts
  elif command -v pipx &>/dev/null; then
    pipx install piper-tts
  else
    echo "ERROR: Neither 'uv' nor 'pipx' found. Please install one of them first."
    exit 1
  fi
else
  echo "piper already installed."
fi

# --- piper voice model ---
PIPER_DIR="${HOME}/.local/share/piper-voices"
PIPER_VOICE="${PIPER_DIR}/en_US-ryan-high.onnx"

if [ ! -f "$PIPER_VOICE" ]; then
  echo "Downloading Piper voice model (~120 MB)..."
  mkdir -p "$PIPER_DIR"
  curl -L -o "$PIPER_VOICE" \
    https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx
  curl -L -o "${PIPER_VOICE}.json" \
    https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json
else
  echo "Piper voice model already present."
fi

# --- PATH reminder ---
echo ""
echo "=== Setup complete ==="
echo "Make sure ~/.local/bin is on your PATH:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo ""
echo "Restart OpenCode after installing the npm plugin:"
echo "  npm install @renjfk/opencode-voice"
