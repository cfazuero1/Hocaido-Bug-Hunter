#!/usr/bin/env bash
# =============================================================================
# Claude Bug Bounty — full installer
# Installs: skills, agents, commands, rules, hooks
#           + Caido MCP server, HackerOne MCP server
#           + registers MCPs with Claude Code
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"
AGENTS_DIR="${CLAUDE_DIR}/agents"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
RULES_DIR="${CLAUDE_DIR}/rules"
LOCAL_BIN="${HOME}/.local/bin"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}[+]${NC} $1"; }
log_err()  { echo -e "${RED}[-]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_info() { echo -e "${BLUE}[*]${NC} $1"; }

mkdir -p "${SKILLS_DIR}" "${AGENTS_DIR}" "${COMMANDS_DIR}" "${RULES_DIR}" "${LOCAL_BIN}"

echo "============================================="
echo "  Claude Bug Bounty — full installer"
echo "============================================="
echo "  source: ${SCRIPT_DIR}"
echo "  target: ${CLAUDE_DIR}"
echo "============================================="
echo ""

# -----------------------------------------------------------------------------
# 1. Skills  (copy full directories — preserves assets like ca.crt, README.md)
# -----------------------------------------------------------------------------
log_info "Installing skills..."
if [ -d "${SCRIPT_DIR}/skills" ]; then
    for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        # Must contain SKILL.md to be a valid skill
        if [ ! -f "${skill_dir}SKILL.md" ]; then
            log_warn "skipped ${skill_name} (no SKILL.md)"
            continue
        fi
        rm -rf "${SKILLS_DIR}/${skill_name}"
        # Exclude node_modules from copy — reinstalled fresh in destination
        # to avoid shipping host-specific binaries.
        if command -v rsync &>/dev/null; then
            rsync -a --exclude 'node_modules' "${skill_dir}" "${SKILLS_DIR}/${skill_name}/"
        else
            cp -R "${skill_dir}" "${SKILLS_DIR}/${skill_name}"
            rm -rf "${SKILLS_DIR}/${skill_name}/node_modules"
        fi
        log_ok "skill: ${skill_name}"

        # If the skill is a Node.js project, install its dependencies
        # in the destination so `tsx`/SDK/native modules resolve correctly.
        if [ -f "${SKILLS_DIR}/${skill_name}/package.json" ]; then
            if command -v npm &>/dev/null; then
                pushd "${SKILLS_DIR}/${skill_name}" >/dev/null
                if npm install --silent --no-audit --no-fund 2>/dev/null; then
                    log_ok "  └─ npm install (${skill_name})"
                else
                    log_err "  └─ npm install failed for ${skill_name} — run 'cd ${SKILLS_DIR}/${skill_name} && npm install' manually"
                fi
                popd >/dev/null
            else
                log_warn "  └─ ${skill_name} needs npm — run 'cd ${SKILLS_DIR}/${skill_name} && npm install' after installing Node.js"
            fi
        fi
    done
else
    log_warn "no skills/ directory found"
fi

# -----------------------------------------------------------------------------
# 2. Agents
# -----------------------------------------------------------------------------
echo ""
log_info "Installing agents..."
if [ -d "${SCRIPT_DIR}/agents" ]; then
    for agent_file in "${SCRIPT_DIR}/agents"/*.md; do
        [ -f "$agent_file" ] || continue
        cp "$agent_file" "${AGENTS_DIR}/"
        log_ok "agent: $(basename "$agent_file")"
    done
else
    log_warn "no agents/ directory found"
fi

# -----------------------------------------------------------------------------
# 3. Commands (slash commands)
# -----------------------------------------------------------------------------
echo ""
log_info "Installing slash commands..."
if [ -d "${SCRIPT_DIR}/commands" ]; then
    for cmd_file in "${SCRIPT_DIR}/commands"/*.md; do
        [ -f "$cmd_file" ] || continue
        cp "$cmd_file" "${COMMANDS_DIR}/"
        log_ok "command: /$(basename "$cmd_file" .md)"
    done
else
    log_warn "no commands/ directory found"
fi

# -----------------------------------------------------------------------------
# 4. Rules (informational markdown — dropped into ~/.claude/rules/)
# -----------------------------------------------------------------------------
echo ""
log_info "Installing rules..."
if [ -d "${SCRIPT_DIR}/rules" ]; then
    for rule_file in "${SCRIPT_DIR}/rules"/*.md; do
        [ -f "$rule_file" ] || continue
        cp "$rule_file" "${RULES_DIR}/"
        log_ok "rule: $(basename "$rule_file")"
    done
else
    log_warn "no rules/ directory found"
fi

# -----------------------------------------------------------------------------
# 5. Hooks (merged via jq if available, otherwise shown to user)
# -----------------------------------------------------------------------------
echo ""
log_info "Installing hooks..."
HOOKS_SRC="${SCRIPT_DIR}/hooks/hooks.json"
HOOKS_DEST="${CLAUDE_DIR}/hooks.json"
if [ -f "$HOOKS_SRC" ]; then
    cp "$HOOKS_SRC" "$HOOKS_DEST"
    log_ok "hooks copied to ${HOOKS_DEST}"
    log_warn "hooks must be referenced from settings.json — see README for format"
else
    log_warn "no hooks/hooks.json found"
fi

# -----------------------------------------------------------------------------
# 6. Caido MCP server binary (from mcp/caido-mcp-server-main/install.sh)
# -----------------------------------------------------------------------------
echo ""
log_info "Installing Caido MCP server..."
CAIDO_MCP_BIN="${LOCAL_BIN}/caido-mcp-server"
if [ -x "$CAIDO_MCP_BIN" ]; then
    log_ok "caido-mcp-server already at ${CAIDO_MCP_BIN}"
else
    CAIDO_MCP_INSTALLER="${SCRIPT_DIR}/mcp/caido-mcp-server-main/install.sh"
    if [ -f "$CAIDO_MCP_INSTALLER" ]; then
        INSTALL_DIR="${LOCAL_BIN}" TOOL=mcp bash "$CAIDO_MCP_INSTALLER" \
            && log_ok "caido-mcp-server installed to ${CAIDO_MCP_BIN}" \
            || log_err "caido-mcp-server install failed"
    else
        log_err "missing ${CAIDO_MCP_INSTALLER}"
    fi
fi

# Also install caido-cli (handy for status/login)
if [ ! -x "${LOCAL_BIN}/caido-cli" ]; then
    CAIDO_MCP_INSTALLER="${SCRIPT_DIR}/mcp/caido-mcp-server-main/install.sh"
    if [ -f "$CAIDO_MCP_INSTALLER" ]; then
        INSTALL_DIR="${LOCAL_BIN}" TOOL=cli bash "$CAIDO_MCP_INSTALLER" \
            && log_ok "caido-cli installed to ${LOCAL_BIN}/caido-cli" \
            || log_warn "caido-cli install failed (non-fatal)"
    fi
fi

# -----------------------------------------------------------------------------
# 7. HackerOne MCP server (Node.js — build from source)
# -----------------------------------------------------------------------------
echo ""
log_info "Building HackerOne MCP server..."
H1_MCP_DIR="${SCRIPT_DIR}/mcp/hackerone-mcp-server"
if [ -d "$H1_MCP_DIR" ]; then
    if command -v npm &>/dev/null; then
        pushd "$H1_MCP_DIR" >/dev/null
        if [ ! -d node_modules ]; then
            npm install --silent && log_ok "npm install" || log_err "npm install failed"
        else
            log_ok "node_modules already present"
        fi
        if [ ! -f dist/index.js ]; then
            npm run build --silent && log_ok "tsc build" || log_err "build failed"
        else
            log_ok "dist/index.js already built"
        fi
        popd >/dev/null
    else
        log_err "npm not installed — skip HackerOne MCP build (install Node.js first)"
    fi
else
    log_warn "no mcp/hackerone-mcp-server directory found"
fi

# -----------------------------------------------------------------------------
# 8. Register MCPs with Claude Code
# -----------------------------------------------------------------------------
echo ""
log_info "Registering MCPs with Claude Code..."

# Credentials are read from env vars only. Never bundled with the installer.
# Set these in your shell before running, e.g.:
#   export CAIDO_PAT=caido_xxx
#   export H1_USERNAME=yourname
#   export H1_API_TOKEN=xxx
CAIDO_PAT="${CAIDO_PAT:-}"
CAIDO_URL="${CAIDO_URL:-http://127.0.0.1:8081}"
H1_API_TOKEN="${H1_API_TOKEN:-}"
H1_USERNAME="${H1_USERNAME:-}"

H1_DIST="${H1_MCP_DIR}/dist/index.js"

print_manual_mcp_hints() {
    log_info "To register MCPs later, export your credentials and run:"
    [ -x "$CAIDO_MCP_BIN" ] && \
        echo "    CAIDO_PAT=<your-pat> claude mcp add caido -s user -e CAIDO_URL=$CAIDO_URL -e CAIDO_PAT=\"\$CAIDO_PAT\" -- $CAIDO_MCP_BIN serve"
    [ -f "$H1_DIST" ] && \
        echo "    H1_USERNAME=<user> H1_API_TOKEN=<token> claude mcp add hackerone -s user -e H1_USERNAME=\"\$H1_USERNAME\" -e H1_API_TOKEN=\"\$H1_API_TOKEN\" -- node $H1_DIST"
}

if command -v claude &>/dev/null; then
    # Caido
    if [ -x "$CAIDO_MCP_BIN" ] && [ -n "$CAIDO_PAT" ]; then
        claude mcp remove caido -s user 2>/dev/null || true
        if claude mcp add caido \
                -s user \
                -e CAIDO_URL="$CAIDO_URL" \
                -e CAIDO_PAT="$CAIDO_PAT" \
                -- "$CAIDO_MCP_BIN" serve; then
            log_ok "registered MCP: caido"
        else
            log_err "failed to register caido MCP"
        fi
    elif [ -x "$CAIDO_MCP_BIN" ]; then
        log_warn "skipped caido MCP registration — set CAIDO_PAT env var and re-run, or register manually"
    else
        log_warn "skipped caido MCP registration (binary missing)"
    fi

    # HackerOne
    if [ -f "$H1_DIST" ] && [ -n "$H1_API_TOKEN" ] && [ -n "$H1_USERNAME" ]; then
        claude mcp remove hackerone -s user 2>/dev/null || true
        if claude mcp add hackerone \
                -s user \
                -e H1_USERNAME="$H1_USERNAME" \
                -e H1_API_TOKEN="$H1_API_TOKEN" \
                -- node "$H1_DIST"; then
            log_ok "registered MCP: hackerone"
        else
            log_err "failed to register hackerone MCP"
        fi
    elif [ -f "$H1_DIST" ]; then
        log_warn "skipped hackerone MCP registration — set H1_USERNAME and H1_API_TOKEN env vars and re-run, or register manually"
    else
        log_warn "skipped hackerone MCP registration (dist missing — build failed?)"
    fi

    # Show manual hints if anything was skipped
    if { [ -x "$CAIDO_MCP_BIN" ] && [ -z "$CAIDO_PAT" ]; } || \
       { [ -f "$H1_DIST" ] && { [ -z "$H1_API_TOKEN" ] || [ -z "$H1_USERNAME" ]; }; }; then
        echo ""
        print_manual_mcp_hints
    fi
else
    log_warn "claude CLI not on PATH — MCP registration skipped"
    print_manual_mcp_hints
fi

# -----------------------------------------------------------------------------
# 9. PATH hint
# -----------------------------------------------------------------------------
echo ""
if [[ ":$PATH:" != *":${LOCAL_BIN}:"* ]]; then
    log_warn "${LOCAL_BIN} is not on your PATH — add to ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Installation complete"
echo "============================================="
echo "  skills   → ${SKILLS_DIR}"
echo "  agents   → ${AGENTS_DIR}"
echo "  commands → ${COMMANDS_DIR}"
echo "  rules    → ${RULES_DIR}"
echo "  binaries → ${LOCAL_BIN}"
echo ""
echo "Next:"
echo "  1. ./install_tools.sh          # recon tools + Caido desktop/CLI"
echo "  2. Configure credentials (not shipped with this repo):"
echo "       export CAIDO_PAT=caido_xxx           # Caido personal access token"
echo "       export H1_USERNAME=<your-h1-user>"
echo "       export H1_API_TOKEN=<your-h1-token>"
echo "     Then re-run ./install.sh to register MCPs, or run the"
echo "     'claude mcp add ...' commands printed above manually."
echo "  3. Initialize the caido-mode skill (one-time, uses your PAT):"
echo "       npx tsx ${SKILLS_DIR}/caido-mode/caido-client.ts setup \"\$CAIDO_PAT\""
echo "       npx tsx ${SKILLS_DIR}/caido-mode/caido-client.ts health"
echo "     Or skip setup and rely on the CAIDO_PAT env var at runtime."
echo "  4. claude mcp list             # verify MCPs"
echo "  5. claude                      # start hunting"
echo "     /recon target.com"
echo "     /hunt target.com"
echo "============================================="
