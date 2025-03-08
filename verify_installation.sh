#!/usr/bin/env bash

# =============================================================================
# Dotfiles Installation Verification Script
# 
# This script verifies the successful installation of dotfiles and related tools.
# It provides detailed feedback on what's installed and configured correctly.
# =============================================================================

# Strict mode
set -uo pipefail

# Prevent tmux from starting a session during verification
export TMUX=""
export TMUX_TMPDIR="/dev/null"  # Prevent socket creation

# Flag to completely disable tmux checks if needed
SKIP_TMUX_CHECKS=${SKIP_TMUX_CHECKS:-""}

# =============================================================================
# Color definitions
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Display functions
# =============================================================================

print_header() {
    printf "\n${MAGENTA}=== %s ===${NC}\n" "$1"
}

print_section() {
    printf "\n${CYAN}%s${NC}\n" "$1"
}

print_success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}!${NC} %s\n" "$1"
}

print_info() {
    printf "   %s\n" "$1"
}

# =============================================================================
# Utility functions
# =============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check symbolic links
check_link() {
    local source=$1
    local target=$2
    
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        print_success "Symlink exists: $target -> $source"
        return 0
    else
        print_error "Symlink missing or incorrect: $target"
        if [ -L "$target" ]; then
            print_info "Current link: $(readlink "$target")"
        elif [ -e "$target" ]; then
            print_info "Exists as a regular file/directory"
        else
            print_info "File does not exist"
        fi
        return 1
    fi
}

# Check tool installation
check_tool() {
    local tool_name=$1
    local command_name=${2:-$tool_name}
    
    print_section "Checking $tool_name"
    
    if command_exists "$command_name"; then
        print_success "$tool_name is installed"
        
        # Show path
        tool_path=$(which "$command_name")
        print_info "Path: $tool_path"
        
        # Try to get version - handle tools specially
        local version_output
        case "$tool_name" in
            "tmux")
                # Special case for tmux - use package manager if available to avoid starting tmux
                if command_exists dpkg && dpkg -l tmux >/dev/null 2>&1; then
                    version_output=$(dpkg -l tmux | grep tmux | awk '{print $3}')
                elif command_exists rpm && rpm -q tmux >/dev/null 2>&1; then
                    version_output=$(rpm -q --qf "%{VERSION}" tmux)
                elif command_exists brew && brew list tmux >/dev/null 2>&1; then
                    version_output=$(brew info --json tmux | grep -o '"installed":\["[^"]*' | cut -d'"' -f4)
                elif command_exists pacman && pacman -Q tmux >/dev/null 2>&1; then
                    version_output=$(pacman -Q tmux | awk '{print $2}')
                else
                    # Last resort: try to get version directly from binary without starting server
                    # Create /dev/null socket and prevent server
                    mkdir -p /tmp/tmux-$(id -u)
                    chmod 700 /tmp/tmux-$(id -u)
                    version_output=$(TMUX= TMUX_TMPDIR=/tmp tmux -V 2>/dev/null || echo "Version unknown")
                    rm -rf /tmp/tmux-$(id -u)
                fi
                print_info "Version: $version_output"
                ;;
            *)
                # For other tools, try common version flags
                version_output=$("$command_name" --version 2>&1 || "$command_name" -v 2>&1 || echo "Version info not available")
                print_info "Version: ${version_output:0:80}..." # Trim to 80 chars to avoid overwhelming output
                ;;
        esac
        
        # Additional tool-specific checks
        case "$tool_name" in
            "zoxide")
                # Test if zoxide is functional
                print_info "Testing functionality..."
                if zoxide --help &>/dev/null; then
                    print_success "zoxide is functioning properly"
                else
                    print_error "zoxide has issues running"
                fi
                ;;
            "thefuck")
                # Test if thefuck is functional
                print_info "Testing functionality..."
                if thefuck --alias &>/dev/null; then
                    print_success "thefuck is functioning properly"
                else
                    print_error "thefuck has issues running"
                fi
                ;;
            "colorls")
                # Check if colorls can list files
                print_info "Testing functionality..."
                if colorls --help &>/dev/null; then
                    print_success "colorls is functioning properly"
                else
                    print_error "colorls has issues running"
                fi
                ;;
            "fzf")
                # Check if fzf is functioning
                print_info "Testing functionality..."
                if echo "test" | fzf --filter="test" &>/dev/null; then
                    print_success "fzf is functioning properly"
                else
                    print_error "fzf has issues running"
                fi
                ;;
            "kitty")
                # Check if kitty can show its version without launching
                print_info "Testing kitty configuration..."
                if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
                    print_success "kitty configuration file exists"
                else
                    print_error "kitty configuration file not found"
                fi
                ;;
            "nvim")
                # Check if nvim health status
                print_info "Checking if nvim can start..."
                if nvim --version | head -n1 &>/dev/null; then
                    print_success "nvim can start"
                else
                    print_error "nvim has issues starting"
                fi
                ;;
        esac
        return 0
    else
        print_error "$tool_name is not installed or not in PATH"
        
        # Look for the command in common locations
        print_info "Searching for $command_name in common locations..."
        
        # Define common locations to search
        # Get Ruby Gem user dir safely
        GEM_USER_BIN=""
        if command_exists ruby; then
            GEM_USER_BIN="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)/bin"
        fi
        
        common_locations=(
            "$HOME/.local/bin"
            "$HOME/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "$GEM_USER_BIN"
            "$HOME/.fzf/bin"  # For fzf installed via git
        )
        
        found=false
        for location in "${common_locations[@]}"; do
            # Skip empty paths
            [ -z "$location" ] && continue
            
            if [ -x "$location/$command_name" ]; then
                print_warning "Found at: $location/$command_name (not in PATH)"
                found=true
            fi
        done
        
        if [ "$found" = false ]; then
            print_error "Not found in common locations"
        fi
        
        # For specific tools, provide helpful tips
        case "$tool_name" in
            "zoxide"|"thefuck"|"fzf")
                print_info "Tip: Make sure to source your shell configuration or restart your terminal after installation"
                print_info "Your PATH is currently: $PATH"
                ;;
        esac
        return 1
    fi
}

# =============================================================================
# Checking functions for different components
# =============================================================================

check_core_tools() {
    print_header "Checking Core Tools"
    
    local tools=("Neovim:nvim" "Kitty:kitty" "Ruby:ruby" "Colorls:colorls" "Zoxide:zoxide" "TheFuck:thefuck" "Fuzzy Finder:fzf")
    
    # Only add tmux to the tools list if we're not skipping tmux checks
    if [ -z "$SKIP_TMUX_CHECKS" ]; then
        tools+=("Tmux:tmux")
    else
        print_warning "Skipping tmux checks as requested by SKIP_TMUX_CHECKS"
    fi
    
    local tool_status=()
    
    for tool_pair in "${tools[@]}"; do
        IFS=':' read -r tool_name command_name <<< "$tool_pair"
        if check_tool "$tool_name" "$command_name"; then
            tool_status+=("$tool_name:installed")
        else
            tool_status+=("$tool_name:missing")
        fi
    done
    
    # Will use tool_status array for summary later
    TOOL_STATUS=("${tool_status[@]}")
}

check_path_configuration() {
    print_header "Checking PATH Configuration"
    
    print_info "PATH: $PATH"
    
    # Get Ruby Gem user dir safely
    GEM_USER_BIN=""
    if command_exists ruby; then
        GEM_USER_BIN="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)/bin"
    fi
    
    # Important directories that should be in PATH
    important_dirs=(
        "$HOME/.local/bin"
        "$HOME/bin"
        "$GEM_USER_BIN"
    )
    
    # Only check for .fzf/bin if fzf isn't already found in system paths
    if command_exists fzf; then
        FZF_PATH=$(which fzf)
        # If fzf is not in a system dir, add .fzf/bin to important_dirs
        if [[ "$FZF_PATH" == "$HOME"* ]]; then
            important_dirs+=("$HOME/.fzf/bin")
        else
            print_success "fzf is already installed system-wide at $FZF_PATH"
        fi
    else
        # If fzf is not found at all, check the git installation directory
        important_dirs+=("$HOME/.fzf/bin")
    fi
    
    for dir in "${important_dirs[@]}"; do
        # Skip empty paths
        [ -z "$dir" ] && continue
        
        if [[ ":$PATH:" == *":$dir:"* ]]; then
            print_success "$dir is in PATH"
        else
            print_error "$dir is NOT in PATH"
        fi
        
        # Check if directory exists
        if [ -d "$dir" ]; then
            file_count=$(ls -1 "$dir" 2>/dev/null | wc -l)
            print_info "Directory exists with $file_count files"
            
            # List important files in these directories
            if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
                key_files=$(find "$dir" -type f -executable -name 'zoxide' -o -name 'thefuck' -o -name 'colorls' -o -name 'fzf' 2>/dev/null | xargs basename 2>/dev/null | tr '\n' ' ')
                if [ -n "$key_files" ]; then
                    print_info "Key files: $key_files"
                fi
            fi
        else
            print_warning "Directory does not exist"
        fi
    done
}

check_symlinks() {
    print_header "Checking Configuration Symlinks"
    
    print_section "Checking ZSH configuration"
check_link "$HOME/.dotfiles/zsh/.zshrc" "$HOME/.zshrc"
check_link "$HOME/.dotfiles/zsh/.zprofile" "$HOME/.zprofile"

    print_section "Checking Neovim configuration"
check_link "$HOME/.dotfiles/nvim/init.lua" "$HOME/.config/nvim/init.lua"
check_link "$HOME/.dotfiles/nvim/lua" "$HOME/.config/nvim/lua"
check_link "$HOME/.dotfiles/nvim/after" "$HOME/.config/nvim/after"

    print_section "Checking Kitty configuration"
check_link "$HOME/.dotfiles/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
check_link "$HOME/.dotfiles/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"

    print_section "Checking Tmux configuration"
check_link "$HOME/.dotfiles/tmux/.tmux.conf" "$HOME/.tmux.conf"

    print_section "Checking Colorls configuration"
check_link "$HOME/.dotfiles/colorls/dark_colors.yaml" "$HOME/.config/colorls/dark_colors.yaml"
}

check_oh_my_zsh() {
    print_header "Checking Oh My Zsh Installation"

if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh is installed"
        
        VERSION="Version not found"
        if [ -f "$HOME/.oh-my-zsh/VERSION" ]; then
            VERSION=$(cat "$HOME/.oh-my-zsh/VERSION" 2>/dev/null)
        fi
        print_info "Oh My Zsh version: $VERSION"

# Check ZSH plugins
        print_section "Checking ZSH plugins"
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
        
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
            print_success "zsh-autosuggestions plugin is installed"
            if [ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/.git/refs/heads/master" ]; then
                COMMIT=$(cat "$ZSH_CUSTOM/plugins/zsh-autosuggestions/.git/refs/heads/master")
                print_info "Version/Commit: $COMMIT"
            fi
        else
            print_error "zsh-autosuggestions plugin is not installed"
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
            print_success "zsh-syntax-highlighting plugin is installed"
            if [ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/.git/refs/heads/master" ]; then
                COMMIT=$(cat "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/.git/refs/heads/master")
                print_info "Version/Commit: $COMMIT"
            fi
        else
            print_error "zsh-syntax-highlighting plugin is not installed"
        fi
    else
        print_error "Oh My Zsh is not installed"
    fi
}

check_tmux_plugins() {
    print_header "Checking Tmux Plugin Manager"
    
    # Completely avoid running any tmux commands
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        print_success "Tmux Plugin Manager is installed"
        
        # Check if tpm is a git repository and show version/commit
        if [ -f "$HOME/.tmux/plugins/tpm/.git/refs/heads/master" ]; then
            COMMIT=$(cat "$HOME/.tmux/plugins/tpm/.git/refs/heads/master")
            print_info "TPM version/commit: ${COMMIT:0:10}"
        fi
        
        # Check for installed plugins by examining the filesystem only
        if [ -d "$HOME/.tmux/plugins" ]; then
            # Count only real directories that look like plugins (have a .git directory or README)
            plugin_dirs=$(find "$HOME/.tmux/plugins" -maxdepth 1 -type d -name "[!.]*" | 
                          grep -v "$HOME/.tmux/plugins$" | 
                          while read -r dir; do
                              if [ -f "$dir/README.md" ] || [ -d "$dir/.git" ] || [ -f "$dir/plugin.tmux" ]; then
                                  echo "$dir"
                              fi
                          done)
            
            plugin_count=$(echo "$plugin_dirs" | wc -l)
            print_info "Installed plugins: $plugin_count"
            
            # List the plugin directories found
            echo "$plugin_dirs" | while read -r plugin_dir; do
                if [ -n "$plugin_dir" ]; then
                    plugin_name=$(basename "$plugin_dir")
                    print_info "- $plugin_name"
                fi
            done
        else
            print_warning "No plugins directory found"
        fi
    else
        print_error "Tmux Plugin Manager is not installed"
    fi
}

check_fonts() {
    print_header "Checking Hack Nerd Font Installation"
    
    case "$(uname)" in
        "Darwin")
            # macOS font check
            if [ -d "$HOME/Library/Fonts/Hack"* ] || [ -f "$HOME/Library/Fonts/Hack"* ]; then
                print_success "Hack Nerd Font appears to be installed in user fonts"
                print_info "$(ls -la "$HOME/Library/Fonts/" | grep -i "hack" | head -n 2)"
            elif [ -d "/Library/Fonts/Hack"* ] || [ -f "/Library/Fonts/Hack"* ]; then
                print_success "Hack Nerd Font appears to be installed in system fonts"
                print_info "$(ls -la "/Library/Fonts/" | grep -i "hack" | head -n 2)"
            else
                print_error "Hack Nerd Font does not appear to be installed"
            fi
            ;;
        "Linux")
            # Linux font check
            FONT_DIR="$HOME/.local/share/fonts"
            # Fix: Use proper quoting and check for font files with "Hack" in the name
            if find "$FONT_DIR" -name "*Hack*" -type f 2>/dev/null | grep -q .; then
                print_success "Hack Nerd Font is installed"
                print_info "$(find "$FONT_DIR" -name "*Hack*" -type f 2>/dev/null | head -n 2)"
            else
                print_error "Hack Nerd Font does not appear to be installed in $FONT_DIR"
            fi
            ;;
        *)
            print_warning "Could not determine font installation status on this OS"
            ;;
    esac
}

check_backup_dirs() {
    print_header "Checking for Backup Directory"
    
    if [ -d "$HOME/dotfiles_backup" ]; then
        print_success "Backup directory exists: $HOME/dotfiles_backup"
        print_info "$(ls -la "$HOME/dotfiles_backup" | head -n 5)"
        if [ "$(ls -A "$HOME/dotfiles_backup" | wc -l)" -gt 5 ]; then
            print_info "... and more files"
        fi
    else
        print_warning "No backup directory found (this is normal if no files needed backup)"
    fi
}

print_summary() {
    print_header "Verification Summary"
    
    print_section "Core tools status:"
    
    for status in "${TOOL_STATUS[@]}"; do
        IFS=':' read -r tool_name status_val <<< "$status"
        if [ "$status_val" = "installed" ]; then
            print_success "$tool_name: INSTALLED"
        else
            print_error "$tool_name: MISSING"
        fi
    done
}

# =============================================================================
# Main program
# =============================================================================

main() {
    # Check for Docker environment and PATH issues
    if [[ $PATH != *"$HOME/.local/bin"* ]] && [ -f "$HOME/.dotfiles/docker_path_fix.sh" ]; then
        print_header "Docker Environment Detected with PATH Issues"
        print_error "Warning: Your PATH doesn't include user directories."
        echo "This is common in Docker environments."
        echo ""
        echo "To fix this, run:"
        echo "  1. ${GREEN}source ./docker_path_fix.sh${NC}"
        echo "  2. ${GREEN}source ~/.zshrc${NC}"
        echo "  3. Run this script again"
        echo ""
        read -p "Would you like to continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_header "Comprehensive Dotfiles Installation Verification"
    echo "This script will check all components of your dotfiles installation"
    
    # Note about tmux checks
    if [ -z "$SKIP_TMUX_CHECKS" ]; then
        echo ""
        echo "Note: If tmux starts a session during verification, you can rerun with:"
        echo "  SKIP_TMUX_CHECKS=1 ./verify_installation.sh"
    fi
    
    # Run all checks
    check_core_tools
    check_path_configuration
    check_symlinks
    check_oh_my_zsh
    
    # Only check tmux plugins if we're not skipping tmux checks
    if [ -z "$SKIP_TMUX_CHECKS" ]; then
        check_tmux_plugins
    fi
    
    check_fonts
    check_backup_dirs
    
    # Print summary
    print_summary
    
    print_header "Verification Complete"
    echo "If you see any issues, please run the install.sh script again or install the missing tools manually."
}

# Run the main function
main 