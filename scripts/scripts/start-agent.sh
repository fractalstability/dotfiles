#!/usr/bin/env bash
# start-agent.sh — preflight check + launch OpenCode
# Usage: start-agent.sh [directory]
#
# Reads LITELLM_BASE and LITELLM_API_KEY from ~/.dotfiles-env
# Falls back to sensible defaults if not set.

set -euo pipefail

# Source private env if available
[ -f "$HOME/.dotfiles-env" ] && source "$HOME/.dotfiles-env"

LITELLM_BASE="${LITELLM_BASE:-http://localhost:4000}"
API_KEY="${LITELLM_API_KEY:-}"
TARGET_DIR="${1:-$(pwd)}"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo -e "${CYAN}=== OpenCode Agent Preflight ===${NC}"
echo -e "Target directory: ${YELLOW}${TARGET_DIR}${NC}"
echo ""

if [ -z "$API_KEY" ]; then
  echo -e "${RED}LITELLM_API_KEY not set — check ~/.dotfiles-env${NC}"
  exit 1
fi

# Check LiteLLM proxy via /v1/models (requires auth)
echo -n "Checking LiteLLM proxy (${LITELLM_BASE})... "
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 4 \
  -H "Authorization: Bearer ${API_KEY}" \
  "${LITELLM_BASE}/v1/models")
if [[ "${HTTP_STATUS}" =~ ^2 ]]; then
  echo -e "${GREEN}reachable (HTTP ${HTTP_STATUS})${NC}"
else
  echo -e "${RED}NOT reachable (HTTP ${HTTP_STATUS}) — is LiteLLM up?${NC}"
  exit 1
fi

# Print available models
echo ""
echo -e "${CYAN}Available models:${NC}"
curl -sf --max-time 6 \
  -H "Authorization: Bearer ${API_KEY}" \
  "${LITELLM_BASE}/v1/models" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in sorted(m['id'] for m in data.get('data', [])):
    print(f'  • {m}')
" 2>/dev/null || echo "  (could not parse model list)"

echo ""
echo -e "${CYAN}=== Launching OpenCode in: ${TARGET_DIR} ===${NC}"
export PATH="$HOME/.opencode/bin:$PATH"
cd "${TARGET_DIR}"
exec opencode
