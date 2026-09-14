#!/usr/bin/env bash
set -eo pipefail

INSTALL_ALL_ROLES=false
TARGET_ROLES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) INSTALL_ALL_ROLES=true; shift ;;
    --roles) IFS=',' read -ra TARGET_ROLES <<< "$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
MISE_BIN="$BIN_DIR/mise"
CONFIG_DEST="$HOME/.config/loop"

echo "🦙 Installing Looping Llama..."

# 1. Ensure ~/.local/bin exists
mkdir -p "$BIN_DIR"

# 2. Bootstrap mise if missing
if [ ! -x "$MISE_BIN" ]; then
  echo "[1/6] Installing hermetic toolchain manager (mise)..."
  curl -fsSL https://mise.jdx.dev/mise-latest-linux-x64 > "$MISE_BIN"
  chmod +x "$MISE_BIN"
else
  echo "[1/6] mise already present at $MISE_BIN"
fi

export PATH="$BIN_DIR:$PATH"

# 3. Link engine configs into XDG locations
echo "[2/6] Linking configuration templates to $CONFIG_DEST..."
mkdir -p "$CONFIG_DEST/roles" "$CONFIG_DEST/scopes" "$CONFIG_DEST/environments" "$CONFIG_DEST/litellm" "$HOME/.config/opencode"

ln -sf "$REPO_ROOT/config/loop/config.toml" "$CONFIG_DEST/config.toml"
ln -sf "$REPO_ROOT/config/loop/scopes/"*.toml "$CONFIG_DEST/scopes/"
ln -sf "$REPO_ROOT/config/loop/environments/"*.toml "$CONFIG_DEST/environments/"
ln -sf "$REPO_ROOT/config/loop/roles/"*.toml "$CONFIG_DEST/roles/"
ln -sf "$REPO_ROOT/config/litellm/config.yaml" "$CONFIG_DEST/litellm/config.yaml"
ln -sf "$REPO_ROOT/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"

# Ensure LiteLLM systemd override exists for the Gemini Fixer
mkdir -p "$HOME/.config/systemd/user/litellm.service.d"
cat << SYSTEMD > "$HOME/.config/systemd/user/litellm.service.d/override.conf"
[Service]
Environment="PYTHONPATH=$REPO_ROOT"
Environment="GEMINI_SKIP_THOUGHT_SIGNATURE_VALIDATOR=true"
Environment="LITELLM_GEMINI_SKIP_THOUGHT_SIGNATURE_VALIDATOR=true"
SYSTEMD
if command -v systemctl >/dev/null 2>&1; then systemctl --user daemon-reload 2>/dev/null || true; fi

# 4. Link mise config and run hermetic installation
echo "[3/6] Installing base runtimes and engine tools via mise..."
mkdir -p "$HOME/.config/mise"
ln -sf "$REPO_ROOT/config/mise/config.toml" "$HOME/.config/mise/config.toml"
"$MISE_BIN" trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
"$MISE_BIN" install -y

# 5. Provision OpenCode & LiteLLM via mise runtimes
echo "[4/6] Provisioning agent executables..."
"$MISE_BIN" exec -- uv tool install --force "litellm[proxy]>=1.44.0"

# Bulletproof static binary installation for yq
if ! command -v yq >/dev/null 2>&1 && [ ! -x "$BIN_DIR/yq" ]; then
  echo "Downloading yq static binary..."
  curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o "$BIN_DIR/yq"
  chmod +x "$BIN_DIR/yq"
fi

if ! command -v opencode >/dev/null 2>&1 && [ ! -x "$BIN_DIR/opencode" ]; then
  echo "Installing OpenCode v2 agent CLI..."
  "$MISE_BIN" exec -- npm install -g @opencode/cli
  "$MISE_BIN" reshim
fi

# 6. Direct binary bridging into ~/.local/bin
echo "[5/6] Bridging tool binaries into $BIN_DIR..."
# Note: yq is removed from this loop because we manually dropped it straight into $BIN_DIR
for tool in just cosign jq opencode; do
  tool_path="$("$MISE_BIN" which "$tool" 2>/dev/null || true)"
  if [ -n "$tool_path" ] && [ -x "$tool_path" ]; then
    ln -sf "$tool_path" "$BIN_DIR/$tool"
  fi
done

for bin_script in "$REPO_ROOT/bin/"*; do
  if [ -f "$bin_script" ] || [ -L "$bin_script" ]; then
    ln -sf "$bin_script" "$BIN_DIR/$(basename "$bin_script")"
  fi
done

# 7. Shell hook persistence
echo "[6/6] Checking shell configuration..."
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ] && ! grep -q 'mise activate zsh' "$ZSHRC"; then
  echo '' >> "$ZSHRC"
  echo '# mise toolchain manager' >> "$ZSHRC"
  echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> "$ZSHRC"
  echo "[OK] Added mise activation hook to ~/.zshrc"
fi

echo "✅ Looping Llama installation complete!"
