#!/bin/bash
# scripts/dev/setup-git-ssh.sh - Flexible Git and SSH configuration setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 TextForensics Development Environment Setup${NC}"
echo "=================================================="

# Function to detect and use Git configuration
setup_git_config() {
    echo -e "${BLUE}Checking Git configuration...${NC}"

    # Check if git config exists
    if [ -f "$HOME/.gitconfig" ]; then
        echo -e "${GREEN}✅ Found existing Git config at $HOME/.gitconfig${NC}"

        # Extract current settings
        GIT_USER_NAME=$(git config --global user.name)
        GIT_USER_EMAIL=$(git config --global user.email)

        if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
            echo -e "${YELLOW}⚠️  Git config exists but name or email is missing.${NC}"

            # Prompt for missing information
            if [ -z "$GIT_USER_NAME" ]; then
                read -p "Enter your full name for Git: " GIT_USER_NAME
                git config --global user.name "$GIT_USER_NAME"
            fi

            if [ -z "$GIT_USER_EMAIL" ]; then
                read -p "Enter your email for Git: " GIT_USER_EMAIL
                git config --global user.email "$GIT_USER_EMAIL"
            fi

            echo -e "${GREEN}✅ Git config updated.${NC}"
        else
            echo -e "${GREEN}  Name:  ${GIT_USER_NAME}${NC}"
            echo -e "${GREEN}  Email: ${GIT_USER_EMAIL}${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No Git config found. Setting up new configuration.${NC}"

        # Prompt for Git information
        read -p "Enter your full name for Git: " GIT_USER_NAME
        read -p "Enter your email for Git: " GIT_USER_EMAIL

        # Set up Git config
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"

        echo -e "${GREEN}✅ Git config created.${NC}"
    fi

    # Add the workspace directory to Git's safe directories list
    # This prevents "dubious ownership" errors in Docker
    echo -e "${BLUE}Adding workspace to Git safe directories...${NC}"
    git config --global --add safe.directory /workspace
    git config --global --add safe.directory '*'
    echo -e "${GREEN}✅ Git safe directories configured${NC}"

    # Export for Docker build
    export GIT_USER_NAME
    export GIT_USER_EMAIL
}

# Function to set up SSH keys
setup_ssh_keys() {
    echo -e "\n${BLUE}Checking SSH configuration...${NC}"

    SSH_DIR="$HOME/.ssh"

    # Create SSH directory if it doesn't exist
    if [ ! -d "$SSH_DIR" ]; then
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        echo -e "${GREEN}✅ Created SSH directory${NC}"
    fi

    # Check for existing SSH keys
    if [ -f "$SSH_DIR/id_ed25519" ] || [ -f "$SSH_DIR/id_rsa" ]; then
        echo -e "${GREEN}✅ Found existing SSH keys${NC}"

        # Check if GitHub is in known_hosts
        if ! grep -q "github.com" "$SSH_DIR/known_hosts" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  Adding GitHub to known_hosts${NC}"
            ssh-keyscan -H github.com >> "$SSH_DIR/known_hosts"
        fi
    else
        echo -e "${YELLOW}⚠️  No SSH keys found. Generating new keys...${NC}"

        # Generate Ed25519 key (more secure and recommended)
        ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_DIR/id_ed25519" -N ""

        # Set proper permissions
        chmod 600 "$SSH_DIR/id_ed25519"
        chmod 644 "$SSH_DIR/id_ed25519.pub"

        # Add GitHub to known_hosts
        ssh-keyscan -H github.com >> "$SSH_DIR/known_hosts"

        echo -e "${GREEN}✅ SSH keys generated${NC}"

        # Display public key
        echo -e "\n${BLUE}Your SSH public key (add this to GitHub):${NC}"
        echo "=========================================================="
        cat "$SSH_DIR/id_ed25519.pub"
        echo "=========================================================="
        echo -e "${YELLOW}ℹ️  Add this key to your GitHub account at: https://github.com/settings/keys${NC}"
    fi

    # Start SSH agent and add key
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$SSH_DIR/id_ed25519" 2>/dev/null || ssh-add "$SSH_DIR/id_rsa" 2>/dev/null || true

    echo -e "${GREEN}✅ SSH setup complete${NC}"
}

# Function to update environment variables for Docker build
update_env_file() {
    echo -e "\n${BLUE}Updating environment variables...${NC}"

    ENV_FILE=".env"

    # Create .env file if it doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example "$ENV_FILE"
            echo -e "${GREEN}✅ Created .env file from .env.example${NC}"
        else
            touch "$ENV_FILE"
            echo -e "${YELLOW}⚠️  Created empty .env file${NC}"
        fi
    fi

    # Add or update Git config variables
    if grep -q "GIT_USER_NAME=" "$ENV_FILE"; then
        sed -i "s/GIT_USER_NAME=.*/GIT_USER_NAME=\"$GIT_USER_NAME\"/" "$ENV_FILE"
    else
        echo "GIT_USER_NAME=\"$GIT_USER_NAME\"" >> "$ENV_FILE"
    fi

    if grep -q "GIT_USER_EMAIL=" "$ENV_FILE"; then
        sed -i "s/GIT_USER_EMAIL=.*/GIT_USER_EMAIL=\"$GIT_USER_EMAIL\"/" "$ENV_FILE"
    else
        echo "GIT_USER_EMAIL=\"$GIT_USER_EMAIL\"" >> "$ENV_FILE"
    fi

    echo -e "${GREEN}✅ Environment variables updated in $ENV_FILE${NC}"
}

# Main execution
setup_git_config
setup_ssh_keys
update_env_file

echo -e "\n${GREEN}✅ Development environment setup complete!${NC}"
echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "1. Run: make build-dev  # Build development environment"
echo "2. Run: make dev        # Start development environment"
echo "3. Run: make shell      # Get interactive shell"

echo -e "\n${YELLOW}ℹ️  Your Git and SSH configurations will be automatically mounted into the container.${NC}"
