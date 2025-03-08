# Initialize Homebrew if available
if [ -f "/opt/homebrew/bin/brew" ]; then
    # macOS ARM (Apple Silicon)
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
    # macOS Intel
    eval "$(/usr/local/bin/brew shellenv)"
elif [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    # Linux Homebrew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# Docker-specific PATH additions
export PATH="$PATH:/home/testuser/.local/bin:/home/testuser/bin:/home/testuser/.local/share/gem/ruby/3.0.0/bin"
