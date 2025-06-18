#!/bin/bash

# TextForensics Smart Git & SSH Setup Script
# Auto-detects git config, manages .env file, and sets up SSH keys

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.base"

echo -e "${BLUE}🔧 TextForensics Smart Development Setup${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Function to detect existing git configuration
detect_git_config() {
    local git_name=""
    local git_email=""

    # Try to get from global git config
    if command -v git >/dev/null 2>&1; then
        git_name=$(git config --global user.name 2>/dev/null || echo "")
        git_email=$(git config --global user.email 2>/dev/null || echo "")
    fi

    if [[ -n "$git_name" && -n "$git_email" ]]; then
        echo -e "${GREEN}✅ Found existing git configuration:${NC}"
        echo -e "   Name:  ${CYAN}$git_name${NC}"
        echo -e "   Email: ${CYAN}$git_email${NC}"
        echo -e "${GREEN}✅ Using detected configuration${NC}"
        echo ""

        GIT_USER_NAME="$git_name"
        GIT_USER_EMAIL="$git_email"
    else
        echo -e "${YELLOW}⚠️  No existing git configuration found${NC}"
        get_git_config_interactive
    fi
}

# Function to get git config interactively
get_git_config_interactive() {
    echo -e "${BLUE}📝 Please enter your git configuration:${NC}"

    while [[ -z "$GIT_USER_NAME" ]]; do
        read -p "$(echo -e "${CYAN}Full Name: ${NC}")" GIT_USER_NAME
        if [[ -z "$GIT_USER_NAME" ]]; then
            echo -e "${RED}❌ Name cannot be empty. Please try again.${NC}"
        fi
    done

    while [[ -z "$GIT_USER_EMAIL" ]]; do
        read -p "$(echo -e "${CYAN}Email Address: ${NC}")" GIT_USER_EMAIL
        if [[ -z "$GIT_USER_EMAIL" ]]; then
            echo -e "${RED}❌ Email cannot be empty. Please try again.${NC}"
        elif [[ ! "$GIT_USER_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo -e "${RED}❌ Invalid email format. Please try again.${NC}"
            GIT_USER_EMAIL=""
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Configuration entered:${NC}"
    echo -e "   Name:  ${CYAN}$GIT_USER_NAME${NC}"
    echo -e "   Email: ${CYAN}$GIT_USER_EMAIL${NC}"
}

# Function to update or create .env file
update_env_file() {
    echo -e "${BLUE}📄 Managing .env file...${NC}"

    # Create .env from example if it doesn't exist
    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "$ENV_EXAMPLE" ]]; then
            echo -e "${YELLOW}📋 Creating .env from .env.base${NC}"
            cp "$ENV_EXAMPLE" "$ENV_FILE"
        else
            echo -e "${RED}❌ .env.base not found. Creating minimal .env${NC}"
            cat > "$ENV_FILE" << EOF
# TextForensics Environment Configuration
VERSION=dev
DOCKER_REGISTRY=
JUPYTER_PORT=8888
TENSORBOARD_PORT=6006
API_PORT=8000
WANDB_PORT=8097
GRADIO_PORT=7860

# User permissions for Docker
UID=1000
GID=1000

# Git user configuration
GIT_USER_NAME=""
GIT_USER_EMAIL=""
EOF
        fi
    fi

    # Update git configuration in .env file
    if grep -q "^GIT_USER_NAME=" "$ENV_FILE"; then
        sed -i "s/^GIT_USER_NAME=.*/GIT_USER_NAME=\"$GIT_USER_NAME\"/" "$ENV_FILE"
    else
        echo "" >> "$ENV_FILE"
        echo "GIT_USER_NAME=\"$GIT_USER_NAME\"" >> "$ENV_FILE"
    fi

    if grep -q "^GIT_USER_EMAIL=" "$ENV_FILE"; then
        sed -i "s/^GIT_USER_EMAIL=.*/GIT_USER_EMAIL=\"$GIT_USER_EMAIL\"/" "$ENV_FILE"
    else
        echo "GIT_USER_EMAIL=\"$GIT_USER_EMAIL\"" >> "$ENV_FILE"
    fi

    # Update UID/GID if not set correctly
    local current_uid=$(id -u)
    local current_gid=$(id -g)

    if grep -q "^UID=" "$ENV_FILE"; then
        sed -i "s/^UID=.*/UID=$current_uid/" "$ENV_FILE"
    else
        echo "UID=$current_uid" >> "$ENV_FILE"
    fi

    if grep -q "^GID=" "$ENV_FILE"; then
        sed -i "s/^GID=.*/GID=$current_gid/" "$ENV_FILE"
    else
        echo "GID=$current_gid" >> "$ENV_FILE"
    fi

    echo -e "${GREEN}✅ .env file updated successfully${NC}"
}

# Function to test SSH connection to GitHub
test_github_connection() {
    echo -e "${BLUE}🧪 Testing SSH connection to GitHub...${NC}"

    # Try SSH connection with timeout
    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ SSH connection to GitHub successful!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  SSH connection failed or key not added to GitHub${NC}"
        return 1
    fi
}

# Function to setup SSH keys
setup_ssh_keys() {
    echo -e "${BLUE}🔑 Setting up SSH keys...${NC}"

    local ssh_dir="$HOME/.ssh"
    mkdir -p "$ssh_dir"

    # Add GitHub to known_hosts if not present
    if ! grep -q "github.com" "$ssh_dir/known_hosts" 2>/dev/null; then
        echo -e "${BLUE}🌐 Adding GitHub to known hosts...${NC}"
        ssh-keyscan -H github.com >> "$ssh_dir/known_hosts" 2>/dev/null
    fi

    # Check for existing SSH keys
    if [[ -f "$ssh_dir/id_ed25519" || -f "$ssh_dir/id_rsa" ]]; then
        echo -e "${GREEN}✅ Found existing SSH keys${NC}"

        # Display the public key
        if [[ -f "$ssh_dir/id_ed25519.pub" ]]; then
            echo -e "${CYAN}Ed25519 public key:${NC}"
            cat "$ssh_dir/id_ed25519.pub"
        elif [[ -f "$ssh_dir/id_rsa.pub" ]]; then
            echo -e "${CYAN}RSA public key:${NC}"
            cat "$ssh_dir/id_rsa.pub"
        fi

        echo ""

        # Test if existing keys work with GitHub
        if test_github_connection; then
            echo -e "${GREEN}✅ Existing SSH keys work with GitHub${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Existing keys don't work with GitHub${NC}"
            echo -e "${BLUE}This could mean:${NC}"
            echo -e "  • Key not added to GitHub yet"
            echo -e "  • Different key needed"
            echo -e "  • Network connectivity issues"
            echo ""

            read -p "$(echo -e "${YELLOW}Generate new SSH key? (Y/n): ${NC}")" -n 1 -r
            echo ""

            if [[ $REPLY =~ ^[Nn]$ ]]; then
                echo -e "${CYAN}💡 Manual setup: Add your public key to GitHub and test with:${NC}"
                echo -e "   ${BLUE}ssh -T git@github.com${NC}"
                return 0
            fi
        fi
    fi

    # Generate new SSH key
    echo -e "${BLUE}🔐 Generating new SSH key...${NC}"

    local key_file="$ssh_dir/id_ed25519"
    ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$key_file" -N ""
    chmod 700 "$ssh_dir"
    chmod 600 "$key_file"
    chmod 644 "${key_file}.pub"

    # Display public key
    echo -e "${GREEN}✅ SSH key generated successfully!${NC}"
    echo ""
    echo -e "${PURPLE}🔑 Your public SSH key (add this to GitHub):${NC}"
    echo -e "${CYAN}==========================================${NC}"
    cat "${key_file}.pub"
    echo -e "${CYAN}==========================================${NC}"
    echo ""
}

# Function to configure git globally if not set
configure_git_global() {
    local current_name=$(git config --global user.name 2>/dev/null || echo "")
    local current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -z "$current_name" || -z "$current_email" ]]; then
        echo -e "${BLUE}⚙️  Configuring global git settings...${NC}"
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
        echo -e "${GREEN}✅ Global git configuration updated${NC}"
    else
        echo -e "${GREEN}✅ Global git configuration already set${NC}"
    fi
}

# Function to test SSH connection
test_ssh_connection() {
    echo -e "${BLUE}🧪 Final SSH connection test...${NC}"

    if test_github_connection; then
        echo -e "${GREEN}🎉 All SSH setup complete and working!${NC}"
    else
        echo -e "${CYAN}💡 Next: Add your public key to GitHub and test with:${NC}"
        echo -e "   ${BLUE}ssh -T git@github.com${NC}"
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo -e "${PURPLE}🚀 Setup Complete! Next Steps:${NC}"
    echo -e "${PURPLE}=============================${NC}"
    echo -e "${CYAN}1. Add your SSH public key to GitHub:${NC}"
    echo -e "   ${BLUE}https://github.com/settings/ssh/new${NC}"
    echo ""
    echo -e "${CYAN}2. Test SSH connection:${NC}"
    echo -e "   ${BLUE}ssh -T git@github.com${NC}"
    echo ""
    echo -e "${CYAN}3. Build and start development environment:${NC}"
    echo -e "   ${BLUE}make build-dev${NC}"
    echo -e "   ${BLUE}make dev${NC}"
    echo ""
    echo -e "${CYAN}4. Access development services:${NC}"
    echo -e "   📊 Jupyter Lab: ${BLUE}http://localhost:8888${NC}"
    echo -e "   📈 TensorBoard: ${BLUE}http://localhost:6006${NC}"
    echo -e "   🔍 Wandb: ${BLUE}http://localhost:8097${NC}"
    echo ""
}

# Main execution flow
main() {
    cd "$PROJECT_ROOT"

    # Step 1: Detect or get git configuration
    detect_git_config

    # Step 2: Update .env file
    update_env_file

    # Step 3: Setup SSH keys
    setup_ssh_keys

    # Step 4: Configure global git if needed
    configure_git_global

    # Step 5: Test SSH connection
    test_ssh_connection

    # Step 6: Show next steps
    show_next_steps
}

# Run main function
main "$@"
