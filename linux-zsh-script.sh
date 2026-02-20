#!/usr/bin/env bash
# =============================================================================
#  mysetup.sh — Ubuntu Dev Environment Setup
#  Idempotent: safe to run multiple times
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_step()    { echo -e "\n${YELLOW}══ $1 ══${NC}"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

command_exists() { command -v "$1" &>/dev/null; }

# =============================================================================
#  SECTION 0 — System Update
# =============================================================================
log_step "System Update"
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    apt-transport-https ca-certificates curl software-properties-common \
    git wget unzip build-essential gnupg lsb-release
log_success "System packages up to date"

# =============================================================================
#  SECTION 1 — ZSH
# =============================================================================
log_step "ZSH"
if command_exists zsh; then
    log_warn "zsh already installed — skipping"
else
    sudo apt install -y zsh
    log_success "zsh installed"
fi

# =============================================================================
#  SECTION 2 — Oh My ZSH
# =============================================================================
log_step "Oh My ZSH"
if [ -d "$HOME/.oh-my-zsh" ]; then
    log_warn "Oh My ZSH already installed — skipping"
else
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log_success "Oh My ZSH installed"
fi

# =============================================================================
#  SECTION 3 — ZSH Theme: fino-time
# =============================================================================
log_step "ZSH Theme"
if grep -q 'ZSH_THEME="fino-time"' "$HOME/.zshrc" 2>/dev/null; then
    log_warn "Theme already set to fino-time — skipping"
else
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="fino-time"/' "$HOME/.zshrc"
    log_success "Theme set to fino-time"
fi

# =============================================================================
#  SECTION 4 — ZSH Plugins: zsh-autosuggestions
# =============================================================================
log_step "ZSH Plugin: zsh-autosuggestions"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log_warn "zsh-autosuggestions already installed — skipping"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log_success "zsh-autosuggestions installed"
fi

# =============================================================================
#  SECTION 5 — ZSH Plugin: zsh-syntax-highlighting
# =============================================================================
log_step "ZSH Plugin: zsh-syntax-highlighting"
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    log_warn "zsh-syntax-highlighting already installed — skipping"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log_success "zsh-syntax-highlighting installed"
fi

# =============================================================================
#  SECTION 6 — ZSH Plugin: zsh-nvm
# =============================================================================
log_step "ZSH Plugin: zsh-nvm"
if [ -d "$ZSH_CUSTOM/plugins/zsh-nvm" ]; then
    log_warn "zsh-nvm already installed — skipping"
else
    git clone https://github.com/lukechilds/zsh-nvm \
        "$ZSH_CUSTOM/plugins/zsh-nvm"
    log_success "zsh-nvm installed"
fi

# =============================================================================
#  SECTION 7 — Update plugins=(...) in .zshrc
# =============================================================================
log_step "Updating .zshrc plugins block"
PLUGINS_LINE='plugins=(git ssh-agent zsh-autosuggestions zsh-syntax-highlighting zsh-nvm)'

if grep -q "zsh-autosuggestions" "$HOME/.zshrc" && \
   grep -q "zsh-syntax-highlighting" "$HOME/.zshrc" && \
   grep -q "zsh-nvm" "$HOME/.zshrc"; then
    log_warn "Plugins already configured in .zshrc — skipping"
else
    # Replace any existing plugins=(...) line
    sed -i '/^plugins=(/,/)/d' "$HOME/.zshrc"
    echo "$PLUGINS_LINE" >> "$HOME/.zshrc"
    log_success "Plugins block updated"
fi

# =============================================================================
#  SECTION 8 — Zinit
# =============================================================================
log_step "Zinit"
if [ -d "$HOME/.local/share/zinit/zinit.git" ]; then
    log_warn "Zinit already installed — skipping"
else
    bash -c "$(curl --fail --show-error --silent --location \
        https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
    log_success "Zinit installed"
fi

# =============================================================================
#  SECTION 9 — zplug + enhanCD
# =============================================================================
log_step "zplug"
if [ -d "$HOME/.zplug" ]; then
    log_warn "zplug already installed — skipping"
else
    curl -sL --proto-redir -all,https \
        https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    log_success "zplug installed"
fi

log_step "enhanCD via zplug"
if grep -q "b4b4r07/enhancd" "$HOME/.zshrc" 2>/dev/null; then
    log_warn "enhanCD already configured — skipping"
else
    cat >> "$HOME/.zshrc" << 'EOF'

# ── zplug + enhanCD ──────────────────────────────────────────────────────────
source ~/.zplug/init.zsh
zplug "b4b4r07/enhancd", use:init.sh
if ! zplug check; then
    zplug install
fi
zplug load
EOF
    log_success "enhanCD configured in .zshrc"
fi

# =============================================================================
#  SECTION 10 — Docker
# =============================================================================
log_step "Docker"
if command_exists docker; then
    log_warn "Docker already installed — skipping"
else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    log_success "Docker installed"
fi

# Add current user to docker group
if groups "$USER" | grep -q '\bdocker\b'; then
    log_warn "$USER already in docker group — skipping"
else
    sudo usermod -aG docker "$USER"
    log_warn "Added $USER to docker group — re-login required to take effect"
fi

# =============================================================================
#  SECTION 11 — Portainer
# =============================================================================
log_step "Portainer"
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^portainer$"; then
    log_warn "Portainer container already exists — skipping"
else
    docker volume create portainer_data 2>/dev/null || true
    docker run -d \
        -p 8000:8000 -p 9000:9000 \
        --name=portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    log_success "Portainer started — http://localhost:9000"
fi

# =============================================================================
#  SECTION 12 — Homebrew
# =============================================================================
log_step "Homebrew"
if command_exists brew; then
    log_warn "Homebrew already installed — skipping"
else
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for current session and to shell config
    BREW_PREFIX=""
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        BREW_PREFIX="/home/linuxbrew/.linuxbrew"
    elif [ -d "$HOME/.linuxbrew" ]; then
        BREW_PREFIX="$HOME/.linuxbrew"
    fi

    if [ -n "$BREW_PREFIX" ]; then
        eval "$($BREW_PREFIX/bin/brew shellenv)"
        if ! grep -q "brew shellenv" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Homebrew" >> "$HOME/.zshrc"
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
        fi
    fi
    log_success "Homebrew installed"
fi

# Ensure brew is in PATH for this script session
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# =============================================================================
#  SECTION 13 — Brew Packages
# =============================================================================
log_step "Brew Packages: lazygit, lazydocker, btop, bat"

brew_install() {
    local pkg="$1"; shift
    if brew list "$pkg" &>/dev/null; then
        log_warn "$pkg already installed via brew — skipping"
    else
        brew install "$@" "$pkg"
        log_success "$pkg installed"
    fi
}

brew_install lazygit
brew_install lazydocker jesseduffield/lazydocker/lazydocker
brew_install btop
brew_install bat

# =============================================================================
#  SECTION 14 — uv (Python package manager)
# =============================================================================
log_step "uv"
if command_exists uv; then
    log_warn "uv already installed — skipping"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Add uv to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    if ! grep -q '.local/bin' "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    log_success "uv installed"
fi

# =============================================================================
#  SECTION 16 — Set ZSH as default shell
# =============================================================================
log_step "Default Shell"
if [ "$SHELL" = "$(which zsh)" ]; then
    log_warn "ZSH is already the default shell — skipping"
else
    chsh -s "$(which zsh)"
    log_success "Default shell changed to ZSH — re-login to apply"
fi

# =============================================================================
#  SECTION 17 — Oh My Zsh configuration and Alias placeholder
# =============================================================================
log_step "Oh My Zsh Configuration"

# Add ZSH export path if missing
if grep -q 'export ZSH="$HOME/.oh-my-zsh"' "$HOME/.zshrc" 2>/dev/null; then
    log_warn "ZSH export path already exists — skipping"
else
    echo "" >> "$HOME/.zshrc"
    echo "# Path to your oh-my-zsh installation" >> "$HOME/.zshrc"
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> "$HOME/.zshrc"
    log_success "ZSH export path added"
fi

# Add Oh My Zsh source command if missing
if grep -q 'source $ZSH/oh-my-zsh.sh' "$HOME/.zshrc" 2>/dev/null; then
    log_warn "Oh My Zsh source command already exists — skipping"
else
    echo "" >> "$HOME/.zshrc"
    echo "# Load Oh My Zsh" >> "$HOME/.zshrc"
    echo 'source $ZSH/oh-my-zsh.sh' >> "$HOME/.zshrc"
    log_success "Oh My Zsh source command added"
fi

log_step "Aliases"
if grep -q "alias dev" "$HOME/.zshrc" 2>/dev/null; then
    log_warn "dev alias already exists — skipping"
else
    echo "" >> "$HOME/.zshrc"
    echo "# Custom Aliases" >> "$HOME/.zshrc"
    echo 'alias dev="cd ~/pasta/"' >> "$HOME/.zshrc"
    log_success "dev alias added — update ~/pasta/ path as needed"
fi

# =============================================================================
#  DONE
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Setup Complete! Next steps:               ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  1. Re-login or open a new terminal              ║${NC}"
echo -e "${GREEN}║  2. Run: source ~/.zshrc                         ║${NC}"
echo -e "${GREEN}║  3. nvm install --lts && nvm use --lts           ║${NC}"
echo -e "${GREEN}║  4. npm update -g                                ║${NC}"
echo -e "${GREEN}║  5. Visit http://localhost:9000 for Portainer    ║${NC}"
echo -e "${GREEN}║  6. Edit ~/pasta/ alias in ~/.zshrc              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
