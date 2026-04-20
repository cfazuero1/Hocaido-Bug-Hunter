#!/usr/bin/env bash
# =============================================================================
# Bug Bounty Tool Installer
# Installs recon/exploit tooling + Caido desktop/CLI
# Usage: ./install_tools.sh [--with-cicd-scanner] [--skip-caido]
# =============================================================================

set -euo pipefail

INSTALL_CICD_SCANNER=false
SKIP_CAIDO=false
for arg in "$@"; do
    case "$arg" in
        --with-cicd-scanner) INSTALL_CICD_SCANNER=true ;;
        --skip-caido)        SKIP_CAIDO=true ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}[+]${NC} $1"; }
log_err()  { echo -e "${RED}[-]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_info() { echo -e "${BLUE}[*]${NC} $1"; }

echo "============================================="
echo "  Bug Bounty Tool Installer"
echo "============================================="

# Detect OS
OS_KERNEL=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_NORM="amd64"; ARCH_ALT="x86_64" ;;
    aarch64) ARCH_NORM="arm64"; ARCH_ALT="aarch64" ;;
    arm64)   ARCH_NORM="arm64"; ARCH_ALT="arm64" ;;
    armv6l)  ARCH_NORM="armv6"; ARCH_ALT="armv6" ;;
    *)       ARCH_NORM="$ARCH"; ARCH_ALT="$ARCH" ;;
esac

# -----------------------------------------------------------------------------
# Package manager bootstrap
# -----------------------------------------------------------------------------
HAVE_BREW=false
HAVE_APT=false
HAVE_DPKG=false

if command -v brew &>/dev/null; then HAVE_BREW=true; fi
if command -v apt-get &>/dev/null; then HAVE_APT=true; fi
if command -v dpkg &>/dev/null; then HAVE_DPKG=true; fi

if ! $HAVE_BREW && ! $HAVE_APT; then
    log_warn "No brew or apt found. Install Homebrew? (y/N)"
    read -r ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        HAVE_BREW=true
    fi
fi

# Go bootstrap
if ! command -v go &>/dev/null; then
    log_warn "Go not found — installing..."
    if $HAVE_BREW; then
        brew install go
    elif $HAVE_APT; then
        sudo apt-get update -qq && sudo apt-get install -y golang-go
    fi
fi

# Node bootstrap (needed for HackerOne MCP server + caido-mode skill).
# caido-mode recommends Node v24+; we warn if the installed version is older
# but don't force an upgrade — the user controls their runtime.
NODE_MIN_MAJOR=20
NODE_REC_MAJOR=24
if ! command -v node &>/dev/null; then
    log_warn "Node.js not found — installing..."
    if $HAVE_BREW; then
        brew install node
    elif $HAVE_APT; then
        sudo apt-get update -qq && sudo apt-get install -y nodejs npm
    fi
fi
if command -v node &>/dev/null; then
    NODE_MAJOR=$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')
    if [ -n "$NODE_MAJOR" ] && [ "$NODE_MAJOR" -lt "$NODE_MIN_MAJOR" ] 2>/dev/null; then
        log_err "Node.js v${NODE_MAJOR} is too old — caido-mode skill needs v${NODE_MIN_MAJOR}+ (v${NODE_REC_MAJOR}+ recommended)"
        log_warn "Upgrade via nvm:  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && nvm install ${NODE_REC_MAJOR}"
    elif [ -n "$NODE_MAJOR" ] && [ "$NODE_MAJOR" -lt "$NODE_REC_MAJOR" ] 2>/dev/null; then
        log_warn "Node.js v${NODE_MAJOR} works but caido-mode recommends v${NODE_REC_MAJOR}+"
    else
        log_ok "Node.js $(node -v) OK for caido-mode"
    fi
fi

# -----------------------------------------------------------------------------
# Tools via brew / apt
# -----------------------------------------------------------------------------
PKG_TOOLS=(nmap subfinder httpx nuclei ffuf amass)

echo ""
log_info "Installing recon/exploit tools..."
for tool in "${PKG_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        log_ok "$tool already installed ($(command -v "$tool"))"
        continue
    fi
    echo "    Installing $tool..."
    if $HAVE_BREW && brew install "$tool" 2>/dev/null; then
        log_ok "$tool installed via brew"
    elif $HAVE_APT && sudo apt-get install -y "$tool" 2>/dev/null; then
        log_ok "$tool installed via apt"
    else
        log_err "$tool failed — install manually"
    fi
done

# -----------------------------------------------------------------------------
# Go-installed tools
# -----------------------------------------------------------------------------
echo ""
log_info "Installing Go tools..."

GO_TOOLS=(
    "github.com/lc/gau/v2/cmd/gau@latest"
    "github.com/hahwul/dalfox/v2@latest"
    "github.com/haccer/subjack@latest"
)
GO_TOOL_NAMES=(gau dalfox subjack)

for i in "${!GO_TOOLS[@]}"; do
    tool_name="${GO_TOOL_NAMES[$i]}"
    tool_path="${GO_TOOLS[$i]}"
    if command -v "$tool_name" &>/dev/null; then
        log_ok "$tool_name already installed"
    else
        echo "    Installing $tool_name..."
        if go install "$tool_path" 2>/dev/null; then
            log_ok "$tool_name installed"
        else
            log_err "$tool_name failed"
        fi
    fi
done

# -----------------------------------------------------------------------------
# sisakulint (GitHub Actions SAST)
# -----------------------------------------------------------------------------
echo ""
log_info "Installing sisakulint..."
SISAKULINT_LATEST=$(curl -sI https://github.com/sisaku-security/sisakulint/releases/latest | grep -i '^location:' | grep -oP 'v[\d.]+' || true)
SISAKULINT_LATEST="${SISAKULINT_LATEST#v}"
SISAKULINT_CURRENT=""
if command -v sisakulint &>/dev/null; then
    SISAKULINT_CURRENT=$(sisakulint -version 2>&1 | grep -oP '[\d]+\.[\d]+\.[\d]+' || true)
fi
if [ -n "$SISAKULINT_CURRENT" ] && [ "$SISAKULINT_CURRENT" = "$SISAKULINT_LATEST" ]; then
    log_ok "sisakulint v${SISAKULINT_CURRENT} already up to date"
elif [ -n "$SISAKULINT_LATEST" ]; then
    [ -n "$SISAKULINT_CURRENT" ] && echo "    Upgrading v${SISAKULINT_CURRENT} → v${SISAKULINT_LATEST}..."
    SISAKULINT_URL="https://github.com/sisaku-security/sisakulint/releases/download/v${SISAKULINT_LATEST}/sisakulint_${SISAKULINT_LATEST}_${OS_KERNEL}_${ARCH_NORM}.tar.gz"
    if curl -sL "$SISAKULINT_URL" -o /tmp/sisakulint.tar.gz && \
       tar -xzf /tmp/sisakulint.tar.gz -C /tmp/ && \
       { mv /tmp/sisakulint /usr/local/bin/sisakulint 2>/dev/null || \
         sudo mv /tmp/sisakulint /usr/local/bin/sisakulint; }; then
        rm -f /tmp/sisakulint.tar.gz
        log_ok "sisakulint v${SISAKULINT_LATEST} installed"
    else
        rm -f /tmp/sisakulint.tar.gz /tmp/sisakulint
        log_err "sisakulint install failed — grab manually from https://github.com/sisaku-security/sisakulint/releases"
    fi
else
    log_err "could not fetch sisakulint latest version"
fi

# cicd_scanner wrapper
if [ "$INSTALL_CICD_SCANNER" = true ]; then
    CICD_SCANNER_SRC="$SCRIPT_DIR/tools/cicd_scanner.sh"
    if [ -f "$CICD_SCANNER_SRC" ]; then
        INSTALL_DIR="/usr/local/bin"
        if cp "$CICD_SCANNER_SRC" "$INSTALL_DIR/cicd_scanner" 2>/dev/null || \
           sudo cp "$CICD_SCANNER_SRC" "$INSTALL_DIR/cicd_scanner"; then
            chmod +x "$INSTALL_DIR/cicd_scanner" 2>/dev/null || sudo chmod +x "$INSTALL_DIR/cicd_scanner"
            log_ok "cicd_scanner → $INSTALL_DIR/cicd_scanner"
        else
            mkdir -p "$HOME/bin"
            cp "$CICD_SCANNER_SRC" "$HOME/bin/cicd_scanner"
            chmod +x "$HOME/bin/cicd_scanner"
            log_ok "cicd_scanner → ~/bin/cicd_scanner"
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Caido (desktop + CLI)
# -----------------------------------------------------------------------------
if ! $SKIP_CAIDO; then
    echo ""
    log_info "Installing Caido..."
    CAIDO_MCP_DIR="${SCRIPT_DIR}/mcp/caido-mcp-server-main"

    # Caido desktop (Linux .deb — local or fresh download)
    if [ "$OS_KERNEL" = "linux" ] && $HAVE_DPKG; then
        CAIDO_DEB=""
        for candidate in \
            "${CAIDO_MCP_DIR}/caido-desktop-v0.56.0-linux-x86_64.deb" \
            "${CAIDO_MCP_DIR}/caido-desktop.deb" \
            "${CAIDO_MCP_DIR}/caido.deb"; do
            if [ -f "$candidate" ]; then CAIDO_DEB="$candidate"; break; fi
        done
        if command -v caido &>/dev/null; then
            log_ok "caido desktop already installed"
        elif [ -n "$CAIDO_DEB" ]; then
            echo "    Installing $(basename "$CAIDO_DEB")..."
            if sudo dpkg -i "$CAIDO_DEB" 2>/dev/null || sudo apt-get install -f -y 2>/dev/null; then
                log_ok "caido desktop installed"
            else
                log_err "caido .deb install failed"
            fi
        else
            log_warn "no local caido .deb — grab from https://caido.io"
        fi
    elif [ "$OS_KERNEL" = "darwin" ] && $HAVE_BREW; then
        if brew list --cask caido &>/dev/null; then
            log_ok "caido already installed via brew cask"
        else
            brew install --cask caido 2>/dev/null \
                && log_ok "caido installed" \
                || log_warn "brew caido install failed — download from https://caido.io"
        fi
    else
        log_warn "Caido desktop must be installed manually on this platform (https://caido.io)"
    fi

    # Caido CLI (from bundled tarball, if present)
    CAIDO_CLI_TARBALL="${CAIDO_MCP_DIR}/caido-cli-v0.56.0-linux-${ARCH_ALT}.tar.gz"
    if [ ! -x "/usr/local/bin/caido-cli" ] && [ ! -x "${HOME}/.local/bin/caido-cli" ]; then
        if [ -f "$CAIDO_CLI_TARBALL" ]; then
            echo "    Extracting caido-cli..."
            mkdir -p "${HOME}/.local/bin"
            tar -xzf "$CAIDO_CLI_TARBALL" -C /tmp/ && \
                mv /tmp/caido-cli "${HOME}/.local/bin/caido-cli" 2>/dev/null || true
            chmod +x "${HOME}/.local/bin/caido-cli" 2>/dev/null || true
            if [ -x "${HOME}/.local/bin/caido-cli" ]; then
                log_ok "caido-cli → ~/.local/bin/caido-cli"
            else
                log_warn "caido-cli tarball extraction failed"
            fi
        else
            log_warn "no caido-cli tarball bundled — install.sh will fetch it from GitHub"
        fi
    else
        log_ok "caido-cli already present"
    fi
fi

# -----------------------------------------------------------------------------
# PATH hints
# -----------------------------------------------------------------------------
GOPATH="${GOPATH:-$HOME/go}"
if [[ ":$PATH:" != *":$GOPATH/bin:"* ]]; then
    log_warn "Add Go bin to PATH:  export PATH=\$PATH:$GOPATH/bin"
fi
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    log_warn "Add ~/.local/bin to PATH:  export PATH=\$HOME/.local/bin:\$PATH"
fi

# -----------------------------------------------------------------------------
# Nuclei templates
# -----------------------------------------------------------------------------
echo ""
log_info "Updating nuclei templates..."
if command -v nuclei &>/dev/null; then
    nuclei -update-templates 2>/dev/null || true
    log_ok "nuclei templates updated"
fi

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Verification"
echo "============================================="

ALL_TOOLS=(subfinder httpx nuclei ffuf nmap amass gau dalfox subjack sisakulint caido-cli)
INSTALLED=0
MISSING=0
for tool in "${ALL_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        log_ok "$tool: $(command -v "$tool")"
        INSTALLED=$((INSTALLED + 1))
    else
        log_err "$tool: NOT FOUND"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "============================================="
echo "  Installed: $INSTALLED / ${#ALL_TOOLS[@]}"
[ "$MISSING" -gt 0 ] && echo "  Missing:   $MISSING (see errors above)"
echo "============================================="
echo ""
echo "Next:  ./install.sh   # installs skills, agents, commands, MCPs"
