#!/bin/bash

# Automated Mac Setup Script

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package with error handling
install_package() {
    if brew install --cask "$1"; then
        echo "$1 installed successfully."
    else
        echo "Failed to install $1. Continuing with the next package."
        failed_installs+=("$1")
    fi
}

echo "Starting Mac setup..."

# Install Xcode Command Line Tools
if ! command_exists xcode-select; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || echo "Failed to install Xcode Command Line Tools. Please install manually."
fi

# Install Homebrew
if ! command_exists brew; then
    echo "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        # Add Homebrew to PATH
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Failed to install Homebrew. Please install manually."
        exit 1
    fi
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update || echo "Failed to update Homebrew. Continuing with installation."

# Install common applications
echo "Installing common applications..."
PACKAGES=(
    visual-studio-code
    firefox
    google-chrome
    iterm2
    spotify
    docker
)

failed_installs=()

for package in "${PACKAGES[@]}"; do
    echo "Installing $package..."
    install_package "$package"
done

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        # Change default shell to zsh
        chsh -s $(which zsh) || echo "Failed to change default shell to zsh. Please change manually."
    else
        echo "Failed to install Oh My Zsh. Please install manually."
    fi
else
    echo "Oh My Zsh is already installed."
fi

# Install NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash; then
        # Add NVM to shell configuration
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.zshrc

        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Install latest LTS version of Node.js
        echo "Installing latest LTS version of Node.js..."
        nvm install --lts && nvm use --lts && nvm alias default 'lts/*' || echo "Failed to install Node.js LTS. Please install manually."
    else
        echo "Failed to install NVM. Please install manually."
    fi
else
    echo "NVM is already installed."
fi

# macOS Preferences
echo "Setting macOS preferences..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles YES

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

echo "Setup complete! Some changes may require a restart to take effect."
echo "Please restart your terminal or log out and back in to start using Oh My Zsh and NVM."

if [ ${#failed_installs[@]} -ne 0 ]; then
    echo "The following packages failed to install and may need manual installation:"
    printf '%s\n' "${failed_installs[@]}"
fi
