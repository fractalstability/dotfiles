#!/usr/bin/env bash
# install.sh — link dotfiles + template configs per-host
#
# Usage:
#   cd ~/dotfiles && bash install.sh
#
# Expects:
#   ~/dotfiles          (this repo — public)
#   ~/dotfiles-private  (optional — API keys, host-specific overrides)
#
# On a fresh machine, clone both first:
#   git clone git@github.com:Fractalstability/dotfiles.git ~/dotfiles
#   git clone git@github.com:Fractalstability/dotfiles-private.git ~/dotfiles-private

set -euo pipefail

DOTFILES="$HOME/dotfiles"
PRIVATE="$HOME/dotfiles-private"
HOSTNAME=$(hostname -s)

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; NC='\033[0m'

info()  { echo -e "${CYAN}[dotfiles]${NC} $*"; }
warn()  { echo -e "${YELLOW}[dotfiles]${NC} $*"; }
err()   { echo -e "${RED}[dotfiles]${NC} $*"; }
ok()    { echo -e "${GREEN}  ✔${NC} $*"; }

link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    warn "Backing up existing $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  ok "$dst → $src"
}

echo ""
info "Installing dotfiles for ${YELLOW}${HOSTNAME}${NC}"
echo ""

# ─── Public modules ───────────────────────────────────────────────

info "Linking public dotfiles..."

# zsh
link_file "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

# starship
link_file "$DOTFILES/starship/.config/starship/starship.toml" "$HOME/.config/starship/starship.toml"

# CONVENTIONS.md
link_file "$DOTFILES/dev/dev/CONVENTIONS.md" "$HOME/dev/CONVENTIONS.md"

# ─── Private repo ─────────────────────────────────────────────────

if [ -d "$PRIVATE" ]; then
  info "Found dotfiles-private — linking secrets..."

  # Private env file (API keys, host-specific vars)
  if [ -f "$PRIVATE/dotfiles-env" ]; then
    link_file "$PRIVATE/dotfiles-env" "$HOME/.dotfiles-env"
  else
    warn "No dotfiles-env found in private repo"
  fi
else
  warn "No ~/dotfiles-private found — skipping secrets"
  warn "  git clone git@github.com:Fractalstability/dotfiles-private.git ~/dotfiles-private"
fi

# ─── Template OpenCode config ────────────────────────────────────

info "Templating OpenCode config for ${YELLOW}${HOSTNAME}${NC}..."

TEMPLATE="$DOTFILES/opencode/.config/opencode/opencode.json.template"
TARGET="$HOME/.config/opencode/opencode.json"

if [ -f "$HOME/.dotfiles-env" ]; then
  source "$HOME/.dotfiles-env"
fi

# Resolve LiteLLM base URL per-host
LITELLM_BASE="${LITELLM_BASE:-http://localhost:4000}"
LITELLM_API_KEY="${LITELLM_API_KEY:-CHANGEME}"

mkdir -p "$(dirname "$TARGET")"
sed \
  -e "s|__LITELLM_BASE__|${LITELLM_BASE}|g" \
  -e "s|__LITELLM_API_KEY__|${LITELLM_API_KEY}|g" \
  -e "s|__HOME__|${HOME}|g" \
  "$TEMPLATE" > "$TARGET"

ok "$TARGET (base: ${LITELLM_BASE})"

# ─── OpenCode binary PATH ────────────────────────────────────────

if [ ! -f "$HOME/.opencode/bin/opencode" ]; then
  warn "OpenCode not installed — run: curl -fsSL https://opencode.ai/install | bash"
fi

# ─── Summary ──────────────────────────────────────────────────────

echo ""
info "Done! Summary:"
echo "  Public:  zsh, starship, CONVENTIONS.md"
if [ -d "$PRIVATE" ]; then
  echo "  Private: .dotfiles-env → API keys + host config"
fi
echo "  OpenCode: ~/.config/opencode/opencode.json (templated for ${HOSTNAME})"
echo ""
info "Restart your shell or run: source ~/.zshrc"
echo ""
