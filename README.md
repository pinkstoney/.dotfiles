![ZSH](https://img.shields.io/badge/Shell-ZSH-4EAA25?logo=gnu-bash&logoColor=white)
![Neovim](https://img.shields.io/badge/Editor-Neovim-57A143?logo=neovim&logoColor=white)
![Tmux](https://img.shields.io/badge/Terminal-Tmux-1BB91F?logo=tmux&logoColor=white)
![Kitty](https://img.shields.io/badge/Terminal-Kitty-784421?logo=kitty&logoColor=white)



## Quick Start

### One-Command Installation

```bash
# Clone the repository
git clone https://github.com/pinkstoney/.dotfiles.git ~/.dotfiles

# Run the installation script
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

The installation script will:

1. Detect your operating system
2. Back up your existing configurations
3. Install all required tools and dependencies
4. Set up configuration files via symlinks
5. Install and configure plugins

### Verify Your Installation

After installation, verify that everything is set up correctly:

```bash
# Run the verification script
cd ~/.dotfiles
./verify_installation.sh
```

If you encounter issues with tmux starting during verification:

```bash
# Skip tmux checks if needed
SKIP_TMUX_CHECKS=1 ./verify_installation.sh
```

## Included Tools

### Core Tools

| Tool | Description |
|------|-------------|
| [Neovim](https://neovim.io/) | Modern, powerful text editor |
| [Tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | Fast, feature-rich terminal emulator |
| [Oh My Zsh](https://ohmyz.sh/) | Framework for managing ZSH configuration |
| [Colorls](https://github.com/athityakumar/colorls) | Beautiful alternative to `ls` |
| [Zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter directory navigation |
| [fzf](https://github.com/junegunn/fzf) | Command-line fuzzy finder |
| [TheFuck](https://github.com/nvbn/thefuck) | Corrects your previous console command |

### Plugins

#### Neovim Plugins
- **[packer.nvim](https://github.com/wbthomason/packer.nvim)** - Package manager for Neovim
- **[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)** - Highly extendable fuzzy finder
- **[vague.nvim](https://github.com/vague2k/vague.nvim)** - Modern color scheme
- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)** - Powerful syntax highlighting and code parsing
- **[treesitter-playground](https://github.com/nvim-treesitter/playground)** - View treesitter information
- **[harpoon](https://github.com/theprimeagen/harpoon)** - Quick file navigation within projects
- **[undotree](https://github.com/mbbill/undotree)** - Visualize the undo history tree
- **[vim-fugitive](https://github.com/tpope/vim-fugitive)** - Git integration for Vim/Neovim
- **[lsp-zero.nvim](https://github.com/VonHeikemen/lsp-zero.nvim)** - Easy LSP setup with sensible defaults
- **[mason.nvim](https://github.com/williamboman/mason.nvim)** - Portable package manager for Neovim
- **[mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)** - Bridges mason with lspconfig
- **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)** - Collection of LSP configurations
- **[nvim-cmp](https://github.com/hrsh7th/nvim-cmp)** - Completion engine plugin
- **[cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp)** - LSP source for nvim-cmp
- **[LuaSnip](https://github.com/L3MON4D3/LuaSnip)** - Snippet engine
- **[presence.nvim](https://github.com/andweeb/presence.nvim)** - Discord Rich Presence integration
- **[nvim-dap](https://github.com/mfussenegger/nvim-dap)** - Debug Adapter Protocol client
- **[nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)** - UI for nvim-dap
- **[mason-nvim-dap.nvim](https://github.com/jay-babu/mason-nvim-dap.nvim)** - Bridge between mason and DAP
- **[nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text)** - Adds virtual text support to the debugger

#### Tmux Plugins
- **[tpm](https://github.com/tmux-plugins/tpm)** - Tmux Plugin Manager
- **[tmux-mode-indicator](https://github.com/MunifTanjim/tmux-mode-indicator)** - Displays current tmux mode in status bar
- **[rose-pine/tmux](https://github.com/rose-pine/tmux)** - Rose Pine color theme for Tmux

#### ZSH Plugins
- **[git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)** - Git aliases and functions
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)** - Fish-like auto-suggestions for ZSH
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)** - Fish-like syntax highlighting for ZSH

## Customization

### Themes

The dotfiles come with a beautiful theme setup:

- **Terminal**: Vague theme
- **Tmux**: Rose Pine Moon theme
- **ZSH**: Refined Oh My Zsh theme
- **Neovim**: Vague theme

### Fonts

Includes the Hack Nerd Font for beautiful typography and icons in your terminal.

## Installation Logs

The installation script creates detailed logs in the backup directory:

```
~/dotfiles_backup/YYYYMMDD_HHMMSS/install.log
```
