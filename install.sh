#!/usr/bin/env bash

# =============================================================================
# Dotfiles Installation Script
# 
# This script installs and configures dotfiles and related tools.
# It handles different operating systems and creates backups of existing files.
# =============================================================================

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Global variables
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$BACKUP_DIR/install.log"

# Add user local bin directories to PATH
export PATH="$PATH:$HOME/.local/bin:$HOME/bin"

# =============================================================================
# Utility Functions
# =============================================================================

# Print colorful messages
print_header() {
    printf "\n\033[1;36m=== %s ===\033[0m\n" "$1"
}

print_success() {
    printf "\033[0;32m✓ %s\033[0m\n" "$1"
}

print_warning() {
    printf "\033[0;33m! %s\033[0m\n" "$1"
}

print_error() {
    printf "\033[0;31m✗ %s\033[0m\n" "$1" >&2
}

print_info() {
    printf "  → %s\n" "$1"
}

# Log messages to a file
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Create a backup of existing files
backup_file() {
    local file="$1"
    log "Checking if backup needed for $file"
    
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        log "Backing up $file to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR/$(dirname "${file#$HOME/}")"
        mv "$file" "$BACKUP_DIR/${file#$HOME/}"
        print_info "Backed up $file to $BACKUP_DIR"
    elif [ -L "$file" ]; then
        log "Removing existing symlink $file"
        rm "$file"
        print_info "Removed existing symlink $file"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            echo "debian"
        elif command_exists dnf; then
            echo "fedora"
        elif command_exists pacman; then
            echo "arch"
        else
            echo "unknown-linux"
        fi
    else
        echo "unknown"
    fi
}

# Exit with error message
fail() {
    print_error "$1"
    log "ERROR: $1"
    exit 1
}

# =============================================================================
# Main Installation Functions
# =============================================================================

# Initialize installation environment
init_installation() {
    # Create backup and log directories
    mkdir -p "$BACKUP_DIR"
    log "Installation started"
    log "Detected OS: $OS"
    
    # Update package lists for debian-based systems
    if [[ "$OS" == "debian" ]]; then
        print_info "Updating package lists for Debian-based system..."
        sudo apt-get update
        log "Updated package lists"
    fi
}

# Install package manager for the current OS
install_package_manager() {
    if [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            print_header "Installing Homebrew"
            log "Installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add brew to path for the current session
            if [ -f "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
                print_success "Homebrew installed (Apple Silicon)"
            elif [ -f "/usr/local/bin/brew" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
                print_success "Homebrew installed (Intel)"
            else
                print_warning "Homebrew installed but couldn't find the executable"
                log "WARNING: Homebrew executable not found in expected locations"
            fi
        else
            print_success "Homebrew is already installed"
        fi
    fi
}

# Install Neovim
install_neovim() {
    print_header "Installing Neovim"
    log "Installing Neovim"
    
    if ! command_exists nvim || [ "$(nvim --version | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')" != "v0.9.4" ]; then
        case "$OS" in
            "macos")
                brew install neovim
                ;;
            "debian")
                print_info "Installing Neovim dependencies..."
                sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential
                
                print_info "Cloning Neovim repository..."
                git clone https://github.com/neovim/neovim --depth=1 --branch=stable /tmp/neovim
                
                print_info "Building Neovim (this may take a few minutes)..."
                cd /tmp/neovim
                make CMAKE_BUILD_TYPE=Release
                
                print_info "Installing Neovim..."
                sudo make install
                
                print_info "Cleaning up..."
                cd - > /dev/null
                rm -rf /tmp/neovim
                ;;
            "fedora")
                sudo dnf install -y neovim
                ;;
            "arch")
                sudo pacman -S --noconfirm neovim
                ;;
            *)
                print_warning "Could not automatically install Neovim for your OS."
                print_warning "Please install Neovim manually: https://github.com/neovim/neovim/wiki/Installing-Neovim"
                log "WARNING: Could not install Neovim automatically on $OS"
                ;;
        esac
        
        if command_exists nvim; then
            print_success "Neovim installed successfully!"
            log "Successfully installed Neovim"
        else
            print_warning "Neovim installation may have failed."
            log "WARNING: Neovim not found after installation attempt"
        fi
    else
        print_success "Neovim is already installed and up to date."
        log "Neovim already installed"
    fi
}

# Install Tmux
install_tmux() {
    print_header "Installing Tmux"
    log "Installing Tmux"
    
    if ! command_exists tmux; then
        case "$OS" in
            "macos")
                brew install tmux
                ;;
            "debian")
                sudo apt-get install -y tmux
                ;;
            "fedora")
                sudo dnf install -y tmux
                ;;
            "arch")
                sudo pacman -S --noconfirm tmux
                ;;
            *)
                print_warning "Could not automatically install Tmux for your OS."
                print_warning "Please install Tmux manually: https://github.com/tmux/tmux/wiki/Installing"
                log "WARNING: Could not install Tmux automatically on $OS"
                ;;
        esac
        
        if command_exists tmux; then
            print_success "Tmux installed successfully!"
            log "Successfully installed Tmux"
        else
            print_warning "Tmux installation may have failed."
            log "WARNING: Tmux not found after installation attempt"
        fi
    else
        print_success "Tmux is already installed."
        log "Tmux already installed"
    fi
}

# Install Kitty Terminal
install_kitty() {
    print_header "Installing Kitty Terminal"
    log "Installing Kitty Terminal"
    
    if ! command_exists kitty; then
        case "$OS" in
            "macos")
                brew install --cask kitty
                ;;
            "debian"|"fedora"|"arch"|"unknown-linux")
                curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
                # Add kitty to path if it's not already there
                if [[ ! -e "$HOME/.local/bin/kitty" ]]; then
                    mkdir -p "$HOME/.local/bin"
                    ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/"
                    print_info "Created symlink for kitty in ~/.local/bin"
                    log "Created symlink for kitty in ~/.local/bin"
                fi
                ;;
            *)
                print_warning "Could not automatically install Kitty for your OS."
                print_warning "Please install Kitty manually: https://sw.kovidgoyal.net/kitty/binary/"
                log "WARNING: Could not install Kitty automatically on $OS"
                ;;
        esac
        
        if command_exists kitty; then
            print_success "Kitty Terminal installed successfully!"
            log "Successfully installed Kitty Terminal"
        else
            print_warning "Kitty Terminal installation may have failed."
            log "WARNING: Kitty not found after installation attempt"
        fi
    else
        print_success "Kitty Terminal is already installed."
        log "Kitty Terminal already installed"
    fi
}

# Install Ruby and Colorls
install_ruby_colorls() {
    print_header "Installing Ruby and Colorls"
    log "Installing Ruby and Colorls"
    
    if ! command_exists ruby; then
        case "$OS" in
            "macos")
                brew install ruby
                ;;
            "debian")
                sudo apt-get install -y ruby-full ruby-dev build-essential
                ;;
            "fedora")
                sudo dnf install -y ruby ruby-devel
                ;;
            "arch")
                sudo pacman -S --noconfirm ruby
                ;;
            *)
                print_warning "Could not automatically install Ruby for your OS."
                print_warning "Please install Ruby manually: https://www.ruby-lang.org/en/documentation/installation/"
                log "WARNING: Could not install Ruby automatically on $OS"
                ;;
        esac
        
        if command_exists ruby; then
            print_success "Ruby installed successfully!"
            log "Successfully installed Ruby"
        else
            print_warning "Ruby installation may have failed."
            log "WARNING: Ruby not found after installation attempt"
            return 1
        fi
    else
        print_success "Ruby is already installed."
        log "Ruby already installed"
    fi
    
    if command_exists ruby; then
        if ! command_exists colorls; then
            print_info "Installing Colorls..."
            log "Installing Colorls"
            
            # Configure gem to install to user directory without sudo
            if [ ! -f "$HOME/.gemrc" ]; then
                echo "gem: --user-install" > "$HOME/.gemrc"
                log "Created .gemrc file"
            fi
            
            # Add local gem bin to PATH permanently and for current session
            GEM_USER_DIR=$(ruby -e 'puts Gem.user_dir')
            GEM_BIN_PATH="$GEM_USER_DIR/bin"
            export PATH="$PATH:$GEM_BIN_PATH"
            
            # Install colorls
            print_info "Running: gem install colorls"
            log "Running gem install colorls"
            gem install colorls
            
            # Verify colorls installation
            if [ -f "$GEM_BIN_PATH/colorls" ]; then
                print_success "Colorls installed successfully in $GEM_BIN_PATH"
                log "Successfully installed Colorls"
            else
                print_warning "Colorls not found in expected location, trying with sudo..."
                log "WARNING: Colorls not found in $GEM_BIN_PATH, trying sudo"
                sudo gem install colorls
                
                if command_exists colorls; then
                    print_success "Colorls installed successfully with sudo"
                    log "Successfully installed Colorls with sudo"
                else
                    print_warning "Colorls installation may have failed"
                    log "WARNING: Colorls not found after installation attempts"
                fi
            fi
        else
            print_success "Colorls is already installed."
            log "Colorls already installed"
        fi
    else
        print_error "Ruby installation failed. Colorls cannot be installed."
        log "ERROR: Ruby installation failed, cannot install Colorls"
    fi
}

# Install Zoxide
install_zoxide() {
    print_header "Installing Zoxide"
    log "Installing Zoxide"
    
    if ! command_exists zoxide; then
        case "$OS" in
            "macos")
                brew install zoxide
                ;;
            "debian")
                sudo apt-get install -y curl
                print_info "Installing Zoxide using the official install script..."
                log "Installing Zoxide using official script"
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
                
                # Ensure zoxide is in PATH for the current session and added to .zshrc
                export PATH="$PATH:$HOME/.local/bin"
                # Check if installation was successful
                if [ -f "$HOME/.local/bin/zoxide" ]; then
                    print_success "Zoxide installed successfully in $HOME/.local/bin/"
                elif [ -f "/usr/local/bin/zoxide" ]; then
                    print_success "Zoxide installed successfully in /usr/local/bin/"
                else
                    print_warning "Could not find zoxide in expected locations, trying alternative installation..."
                    log "WARNING: Zoxide not found, trying alternatives"
                    
                    # Direct installation using cargo if available
                    if command_exists cargo; then
                        log "Installing zoxide with cargo"
                        cargo install zoxide --locked
                    else
                        # Get the latest zoxide binary directly
                        ZOXIDE_VERSION=$(curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
                        print_info "Installing zoxide $ZOXIDE_VERSION directly..."
                        log "Installing zoxide $ZOXIDE_VERSION directly"
                        mkdir -p "$HOME/.local/bin"
                        curl -sL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar xz -C /tmp
                        mv /tmp/zoxide "$HOME/.local/bin/"
                        chmod +x "$HOME/.local/bin/zoxide"
                        export PATH="$PATH:$HOME/.local/bin"
                    fi
                fi
                ;;
            "fedora")
                sudo dnf install -y zoxide
                ;;
            "arch")
                sudo pacman -S --noconfirm zoxide
                ;;
            *)
                print_warning "Could not automatically install Zoxide for your OS."
                print_warning "Please install Zoxide manually: https://github.com/ajeetdsouza/zoxide#installation"
                log "WARNING: Could not install Zoxide automatically on $OS"
                ;;
        esac
        
        # Verify zoxide installation
        if command_exists zoxide; then
            print_success "Zoxide installed successfully. Version: $(zoxide --version)"
            log "Successfully installed Zoxide"
        else
            print_warning "Zoxide installation may have failed. Please check manually."
            log "WARNING: Zoxide not found after installation attempt"
        fi
    else
        print_success "Zoxide is already installed."
        log "Zoxide already installed"
    fi
}

# Install fzf (used by zoxide interactive mode)
install_fzf() {
    print_header "Installing fzf"
    log "Installing fzf"
    
    if ! command_exists fzf; then
        case "$OS" in
            "macos")
                brew install fzf
                # Install fzf key bindings and fuzzy completion
                "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc
                ;;
            "debian")
                sudo apt-get install -y fzf
                ;;
            "fedora")
                sudo dnf install -y fzf
                ;;
            "arch")
                sudo pacman -S --noconfirm fzf
                ;;
            *)
                print_info "Installing fzf using git..."
                log "Installing fzf using git"
                git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
                "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
                ;;
        esac
        
        # Verify fzf installation
        if command_exists fzf; then
            print_success "fzf installed successfully. Version: $(fzf --version)"
            log "Successfully installed fzf"
        else
            print_warning "fzf installation may have failed. Please check manually."
            log "WARNING: fzf not found after installation attempt"
        fi
    else
        print_success "fzf is already installed."
        log "fzf already installed"
    fi
}

# Install TheFuck
install_thefuck() {
    print_header "Installing TheFuck"
    log "Installing TheFuck"
    
    if ! command_exists thefuck; then
        # First check if pip/pip3 is available
        if command_exists pip3; then
            PIP_CMD="pip3"
        elif command_exists pip; then
            PIP_CMD="pip"
        else
            print_info "Installing pip first..."
            log "Installing pip first"
            case "$OS" in
                "macos")
                    brew install python3
                    PIP_CMD="pip3"
                    ;;
                "debian")
                    sudo apt-get install -y python3-pip
                    PIP_CMD="pip3"
                    ;;
                "fedora")
                    sudo dnf install -y python3-pip
                    PIP_CMD="pip3"
                    ;;
                "arch")
                    sudo pacman -S --noconfirm python-pip
                    PIP_CMD="pip"
                    ;;
                *)
                    print_warning "Could not automatically install pip for your OS."
                    print_warning "Please install pip and TheFuck manually."
                    log "WARNING: Could not install pip automatically on $OS"
                    PIP_CMD=""
                    ;;
            esac
        fi

        if [ -n "$PIP_CMD" ]; then
            print_info "Installing TheFuck using $PIP_CMD..."
            log "Installing TheFuck using $PIP_CMD"
            $PIP_CMD install thefuck --user
            
            # Export path for current session
            export PATH="$PATH:$HOME/.local/bin"
            
            # Check if installation was successful
            if [ -f "$HOME/.local/bin/thefuck" ]; then
                print_success "TheFuck installed successfully in $HOME/.local/bin/"
                log "Successfully installed TheFuck"
            else
                print_warning "TheFuck binary not found in expected location. Trying to install with sudo..."
                log "WARNING: TheFuck not found, trying sudo installation"
                # Try installing globally if user installation failed
                sudo $PIP_CMD install thefuck
                
                if command_exists thefuck; then
                    print_success "TheFuck installed successfully with sudo"
                    log "Successfully installed TheFuck with sudo"
                else
                    print_warning "TheFuck installation may have failed"
                    log "WARNING: TheFuck not found after installation attempts"
                fi
            fi
        fi
        
        # Verify thefuck installation
        if command_exists thefuck; then
            print_success "TheFuck installed successfully. Testing initialization..."
            thefuck --version
            log "Successfully verified TheFuck"
        else
            print_warning "TheFuck installation may have failed. Please check manually."
            print_warning "Note: You might need to restart your terminal or source your .zshrc for TheFuck to be available."
            log "WARNING: TheFuck not found after installation attempt"
        fi
    else
        print_success "TheFuck is already installed."
        log "TheFuck already installed"
    fi
}

# Install Hack Nerd Font
install_hack_nerd_font() {
    print_header "Installing Hack Nerd Font"
    log "Installing Hack Nerd Font"
    
    case "$OS" in
        "macos")
            if ! brew list --cask font-hack-nerd-font >/dev/null 2>&1; then
                brew tap homebrew/cask-fonts
                brew install --cask font-hack-nerd-font
                print_success "Hack Nerd Font installed successfully"
                log "Successfully installed Hack Nerd Font"
            else
                print_success "Hack Nerd Font is already installed."
                log "Hack Nerd Font already installed"
            fi
            ;;
        "debian"|"fedora"|"arch"|"unknown-linux")
            FONT_DIR="$HOME/.local/share/fonts"
            mkdir -p "$FONT_DIR"
            
            # Skip if any Hack font files already exist
            if find "$FONT_DIR" -name "*Hack*" -type f 2>/dev/null | grep -q .; then
                print_success "Hack Nerd Font is already installed."
                log "Hack Nerd Font already installed"
                return 0
            fi
            
            print_info "Downloading Hack Nerd Font..."
            log "Downloading Hack Nerd Font"
            
            # Try multiple methods to ensure success
            
            # Method 1: Direct download of individual font files (most reliable)
            if curl -fLo "$FONT_DIR/Hack Regular Nerd Font Complete.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf"; then
                # Try to get bold and italic versions too
                curl -fLo "$FONT_DIR/Hack Bold Nerd Font Complete.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Bold/HackNerdFont-Bold.ttf" || true
                curl -fLo "$FONT_DIR/Hack Italic Nerd Font Complete.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Italic/HackNerdFont-Italic.ttf" || true
                curl -fLo "$FONT_DIR/Hack BoldItalic Nerd Font Complete.ttf" "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/BoldItalic/HackNerdFont-BoldItalic.ttf" || true
                
                print_success "Hack Nerd Font installed successfully (direct method)"
                log "Successfully installed Hack Nerd Font via direct download"
            # Method 2: Download and extract zip file if unzip is available
            elif command_exists unzip; then
                # Updated URL to use the latest Nerd Fonts release
                NERD_FONTS_VERSION="v3.1.1"
                TEMP_ZIP="$(mktemp).zip"
                
                if curl -fLo "$TEMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/Hack.zip"; then
                    print_info "Extracting font files..."
                    TEMP_DIR=$(mktemp -d)
                    
                    if unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"; then
                        # Move all TTF files to font directory
                        find "$TEMP_DIR" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
                        
                        # Verify font files were copied
                        if find "$FONT_DIR" -name "*Hack*" -type f | grep -q .; then
                            print_success "Hack Nerd Font installed successfully (zip method)"
                            log "Successfully installed Hack Nerd Font via zip download"
                        else
                            print_error "No font files found in extracted archive"
                            log "ERROR: No font files found in extracted archive"
                        fi
                    else
                        print_error "Failed to extract font files"
                        log "ERROR: Failed to extract font files from zip"
                    fi
                    
                    # Clean up
                    rm -f "$TEMP_ZIP"
                    rm -rf "$TEMP_DIR"
                else
                    print_error "Failed to download font zip"
                    log "ERROR: Failed to download font from GitHub"
                fi
            # Method 3: Fallback - Clone repository if git is available
            elif command_exists git; then
                print_info "Downloading fonts via git (this may take a while)..."
                log "Downloading fonts via git"
                
                TEMP_DIR=$(mktemp -d)
                if git clone --depth=1 --filter=blob:none --sparse https://github.com/ryanoasis/nerd-fonts.git "$TEMP_DIR"; then
                    cd "$TEMP_DIR"
                    git sparse-checkout set patched-fonts/Hack
                    if [ -d "patched-fonts/Hack" ]; then
                        cp patched-fonts/Hack/Regular/*.ttf "$FONT_DIR/" || true
                        cp patched-fonts/Hack/Bold/*.ttf "$FONT_DIR/" || true
                        cp patched-fonts/Hack/Italic/*.ttf "$FONT_DIR/" || true
                        cp patched-fonts/Hack/BoldItalic/*.ttf "$FONT_DIR/" || true
                        
                        print_success "Hack Nerd Font installed successfully (git method)"
                        log "Successfully installed Hack Nerd Font via git"
                    else
                        print_error "Failed to get font files via git"
                        log "ERROR: Failed to get font files via git"
                    fi
                    cd - > /dev/null
                    rm -rf "$TEMP_DIR"
                else
                    print_error "Failed to clone font repository"
                    log "ERROR: Failed to clone font repository"
                fi
            else
                print_error "Could not install Hack Nerd Font automatically"
                print_warning "Please install it manually: https://www.nerdfonts.com/font-downloads"
                log "ERROR: Could not install Hack Nerd Font automatically"
            fi
            
            # Update font cache if available
            if command_exists fc-cache && find "$FONT_DIR" -name "*Hack*" -type f | grep -q .; then
                print_info "Updating font cache..."
                fc-cache -f -v
                print_success "Font cache updated"
                log "Font cache updated"
            fi
            ;;
        *)
            print_warning "Could not automatically install Hack Nerd Font for your OS."
            print_warning "Please install it manually: https://www.nerdfonts.com/font-downloads"
            log "WARNING: Could not install Hack Nerd Font automatically on $OS"
            ;;
    esac
}

# Install Oh My Zsh and plugins
install_oh_my_zsh() {
    print_header "Setting up Oh My Zsh"
    log "Setting up Oh My Zsh"
    
    # Check if Oh My Zsh is installed first, before ZSH configuration
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Oh My Zsh is not installed. Would you like to install it now?"
        read -p "(y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing Oh My Zsh"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            if [ -d "$HOME/.oh-my-zsh" ]; then
                print_success "Oh My Zsh installed successfully"
                log "Successfully installed Oh My Zsh"
            else
                print_warning "Oh My Zsh installation may have failed"
                log "WARNING: Oh My Zsh directory not found after installation"
            fi
        else
            print_warning "Please install Oh My Zsh manually for the ZSH configuration to work properly."
            log "User declined to install Oh My Zsh"
        fi
    else
        print_success "Oh My Zsh is already installed."
        log "Oh My Zsh already installed"
    fi
    
    # Now that Oh My Zsh is installed (if the user wanted it), set up ZSH configuration
    print_info "Setting up ZSH configuration..."
    log "Setting up ZSH configuration"
    backup_file "$HOME/.zshrc"
    backup_file "$HOME/.zprofile"
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
    print_success "ZSH configuration linked successfully"
    log "Successfully linked ZSH configuration files"
    
    # Installing ZSH plugins
    print_info "Setting up ZSH plugins..."
    log "Setting up ZSH plugins"
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        log "Installing zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        print_success "Installed zsh-autosuggestions plugin"
    else
        print_success "zsh-autosuggestions plugin is already installed"
    fi
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        log "Installing zsh-syntax-highlighting"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        print_success "Installed zsh-syntax-highlighting plugin"
    else
        print_success "zsh-syntax-highlighting plugin is already installed"
    fi
}

# Set up Neovim
setup_neovim() {
    print_header "Setting up Neovim"
    log "Setting up Neovim"
    
    # Setting up Neovim plugin manager (Packer)
    print_info "Setting up Neovim plugin manager (Packer)..."
    log "Setting up Packer plugin manager for Neovim"
    PACKER_DIR="$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
    if [ ! -d "$PACKER_DIR" ]; then
        print_info "Installing Packer.nvim..."
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR"
        print_success "Packer.nvim installed successfully"
        log "Successfully installed Packer.nvim"
    else
        print_success "Packer.nvim is already installed"
        log "Packer.nvim already installed"
    fi

    # Neovim configuration
    print_info "Setting up Neovim configuration..."
    log "Setting up Neovim configuration files"
    backup_file "$HOME/.config/nvim/init.lua"
    mkdir -p "$HOME/.config/nvim"
    ln -sf "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    if [ -d "$HOME/.config/nvim/lua" ]; then
        backup_file "$HOME/.config/nvim/lua"
    fi
    if [ -d "$HOME/.config/nvim/after" ]; then
        backup_file "$HOME/.config/nvim/after"
    fi
    ln -sf "$DOTFILES_DIR/nvim/lua" "$HOME/.config/nvim/lua"
    ln -sf "$DOTFILES_DIR/nvim/after" "$HOME/.config/nvim/after"
    print_success "Neovim configuration linked successfully"
    log "Successfully linked Neovim configuration files"

    # Installing Neovim plugins
    print_info "Installing Neovim plugins with Packer..."
    print_info "This may take a while, please be patient..."
    log "Installing Neovim plugins with Packer"

    # Create a temporary script to run Packer sync in headless mode
    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
# This script runs Neovim in headless mode to install plugins
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
EOF
    chmod +x "$TEMP_SCRIPT"

    # Run the temp script
    print_info "Running PackerSync to install all plugins defined in packer.lua..."
    log "Running PackerSync in headless mode"
    $TEMP_SCRIPT
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        print_success "All Neovim plugins have been installed successfully!"
        log "Successfully installed all Neovim plugins"
    else
        print_warning "There was an issue installing plugins. Falling back to manual installation..."
        log "WARNING: PackerSync failed, trying manual installation"
        
        # Create dirs for plugins
        mkdir -p "$HOME/.local/share/nvim/site/pack/packer/start"
        mkdir -p "$HOME/.local/share/nvim/site/pack/packer/opt"
        
        # Install required plugin
        git clone --depth 1 https://github.com/wbthomason/packer.nvim "$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim"
        
        # Run packer sync again
        $TEMP_SCRIPT
        
        if [ $? -eq 0 ]; then
            print_success "Plugins installed successfully on second attempt!"
            log "Successfully installed Neovim plugins on second attempt"
        else
            print_warning "Warning: Could not automatically install plugins."
            print_warning "Please run ':PackerSync' manually the first time you open Neovim."
            log "WARNING: Failed to install Neovim plugins automatically"
        fi
    fi

    # Clean up temporary script
    rm -f "$TEMP_SCRIPT"
}

# Set up Kitty
setup_kitty() {
    print_header "Setting up Kitty configuration"
    log "Setting up Kitty configuration"
    
    backup_file "$HOME/.config/kitty/kitty.conf"
    backup_file "$HOME/.config/kitty/current-theme.conf"
    mkdir -p "$HOME/.config/kitty"
    ln -sf "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ln -sf "$DOTFILES_DIR/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
    print_success "Kitty configuration linked successfully"
    log "Successfully linked Kitty configuration files"
}

# Set up Tmux
setup_tmux() {
    print_header "Setting up Tmux configuration"
    log "Setting up Tmux configuration"
    
    backup_file "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    print_success "Tmux configuration linked successfully"
    log "Successfully linked Tmux configuration file"
    
    # Check for Tmux Plugin Manager
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        print_info "Installing Tmux Plugin Manager..."
        log "Installing Tmux Plugin Manager"
        mkdir -p "$HOME/.tmux/plugins"
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        print_success "Tmux Plugin Manager installed successfully"
        log "Successfully installed Tmux Plugin Manager"
    else
        print_success "Tmux Plugin Manager is already installed"
        log "Tmux Plugin Manager already installed"
    fi
    
    # Automatically install tmux plugins
    print_info "Installing tmux plugins automatically..."
    log "Installing tmux plugins"
    if command_exists tmux && [ -d "$HOME/.tmux/plugins/tpm" ]; then
        # Start a tmux server in the background if one isn't already running
        tmux start-server
        
        # Create a new session but don't attach to it
        tmux new-session -d
        
        # Run the tpm install command
        print_info "Running TPM install script..."
        "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" > /dev/null
        
        # Kill the session we created
        tmux kill-server
        
        print_success "Tmux plugins including Rose Pine theme have been installed!"
        log "Successfully installed Tmux plugins"
    else
        print_warning "Tmux or TPM not found. Please run 'tmux' and press prefix + I to install plugins manually."
        log "WARNING: Failed to run TPM install script (Tmux or TPM not found)"
    fi
}

# Set up Colorls
setup_colorls() {
    print_header "Setting up Colorls configuration"
    log "Setting up Colorls configuration"
    
    backup_file "$HOME/.config/colorls/dark_colors.yaml"
    mkdir -p "$HOME/.config/colorls"
    ln -sf "$DOTFILES_DIR/colorls/dark_colors.yaml" "$HOME/.config/colorls/dark_colors.yaml"
    print_success "Colorls configuration linked successfully"
    log "Successfully linked Colorls configuration file"
}

# =============================================================================
# Main Program
# =============================================================================

# Detect OS
OS=$(detect_os)

# Welcome message
print_header "Dotfiles Installation Script"
echo ""
echo "This script will install dotfiles from $DOTFILES_DIR"
echo "Any existing configuration will be backed up to $BACKUP_DIR"
echo "Detected OS: $OS"
echo ""
read -p "Continue with installation? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation aborted."
    exit 1
fi

# Initialize installation
init_installation

# Install tools and configurations
install_package_manager
install_neovim
install_tmux
install_kitty
install_ruby_colorls
install_zoxide
install_fzf
install_thefuck
install_hack_nerd_font
install_oh_my_zsh
setup_neovim
setup_kitty
setup_tmux
setup_colorls

# Print completion message
print_header "Installation Complete!"
echo ""
echo "Please restart your terminal or run 'source ~/.zshrc'"
echo "to apply the changes."
echo ""
print_info "If this is your first time installing:"
echo "1. If using Tmux, start tmux and press prefix + I to install plugins"
echo "2. If using ZSH, ensure Oh My Zsh and plugins are working correctly"
echo "3. If using Neovim, launch it and let Packer install all plugins"
echo ""
echo "A log file is available at: $LOG_FILE"

