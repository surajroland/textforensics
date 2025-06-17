#!/bin/bash
# scripts/dev/git-config-init.sh - Git and SSH configuration setup for TextForensics development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 TextForensics Git & SSH Configuration Setup${NC}"
echo "=================================================="

# Function to check if SSH keys exist
check_ssh_keys() {
    local ssh_path="$1"
    if [[ -d "$ssh_path" && (-f "$ssh_path/id_rsa" || -f "$ssh_path/id_ed25519" || -f "$ssh_path/id_ecdsa") ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if git config exists
check_git_config() {
    local git_config="$1"
    if [[ -f "$git_config" ]]; then
        return 0
    else
        return 1
    fi
}

# Dynamic SSH path detection
detect_ssh_paths() {
    local ssh_paths=()

    # Always check WSL/Linux home
    [[ -n "$HOME" ]] && ssh_paths+=("$HOME/.ssh")

    # Check Windows user profiles if in WSL
    if [[ -d "/mnt/c/Users" ]]; then
        # Current user variations
        [[ -n "$USER" ]] && ssh_paths+=("/mnt/c/Users/$USER/.ssh")
        [[ -n "$USERNAME" ]] && ssh_paths+=("/mnt/c/Users/$USERNAME/.ssh")
        ssh_paths+=("/mnt/c/Users/$(whoami)/.ssh")

        # Find all Windows user directories and check for .ssh
        for user_dir in /mnt/c/Users/*/; do
            if [[ -d "${user_dir}.ssh" ]]; then
                ssh_paths+=("${user_dir}.ssh")
            fi
        done
    fi

    # Remove duplicates and return
    printf '%s\n' "${ssh_paths[@]}" | sort -u
}

# Dynamic Git config detection
detect_git_configs() {
    local git_configs=()

    # Always check WSL/Linux home
    [[ -n "$HOME" ]] && git_configs+=("$HOME/.gitconfig")

    # Check Windows user profiles if in WSL
    if [[ -d "/mnt/c/Users" ]]; then
        # Current user variations
        [[ -n "$USER" ]] && git_configs+=("/mnt/c/Users/$USER/.gitconfig")
        [[ -n "$USERNAME" ]] && git_configs+=("/mnt/c/Users/$USERNAME/.gitconfig")
        git_configs+=("/mnt/c/Users/$(whoami)/.gitconfig")

        # Find all Windows user directories and check for .gitconfig
        for user_dir in /mnt/c/Users/*/; do
            if [[ -f "${user_dir}.gitconfig" ]]; then
                git_configs+=("${user_dir}.gitconfig")
            fi
        done
    fi

    # Remove duplicates and return
    printf '%s\n' "${git_configs[@]}" | sort -u
}

echo -e "${BLUE}🔍 Dynamically detecting Git and SSH configurations...${NC}"

# Check for existing SSH keys and Git config
SSH_FOUND=false
GIT_CONFIG_FOUND=false
SSH_PATH=""
GIT_CONFIG_PATH=""

# Dynamic SSH detection
echo -e "${BLUE}Checking SSH key locations:${NC}"
while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    echo -e "  Checking: $path"
    if check_ssh_keys "$path"; then
        echo -e "${GREEN}  ✅ Found SSH keys at: $path${NC}"
        SSH_FOUND=true
        SSH_PATH="$path"
        break
    else
        echo -e "  ❌ No SSH keys found"
    fi
done < <(detect_ssh_paths)

# Dynamic Git config detection
echo -e "\n${BLUE}Checking Git config locations:${NC}"
while IFS= read -r config; do
    [[ -z "$config" ]] && continue
    echo -e "  Checking: $config"
    if check_git_config "$config"; then
        echo -e "${GREEN}  ✅ Found Git config at: $config${NC}"
        GIT_CONFIG_FOUND=true
        GIT_CONFIG_PATH="$config"

        # Show current git config
        echo -e "${BLUE}  Current Git configuration:${NC}"
        echo "    Name:  $(git config --file "$config" user.name 2>/dev/null || echo 'Not set')"
        echo "    Email: $(git config --file "$config" user.email 2>/dev/null || echo 'Not set')"
        break
    else
        echo -e "  ❌ No Git config found"
    fi
done < <(detect_git_configs)

# Update docker-compose.yml based on findings
update_docker_compose() {
    local compose_file="docker-compose.yml"

    if [[ ! -f "$compose_file" ]]; then
        echo -e "${RED}❌ docker-compose.yml not found in current directory${NC}"
        return 1
    fi

    # Create backup
    cp "$compose_file" "${compose_file}.backup"
    echo -e "${BLUE}💾 Backup saved as: ${compose_file}.backup${NC}"

    # Check if mounts already exist
    if grep -q "\.ssh.*root/\.ssh" "$compose_file"; then
        echo -e "${YELLOW}⚠️  SSH mount already exists in docker-compose.yml${NC}"
        return 0
    fi

    # Add volume mounts after workspace volume
    local temp_file=$(mktemp)
    local found_workspace=false

    while IFS= read -r line; do
        echo "$line" >> "$temp_file"

        # Add SSH and Git mounts after workspace volume
        if [[ "$line" == *"- .:/workspace"* ]] && [[ "$found_workspace" == false ]]; then
            found_workspace=true
            if [[ "$SSH_FOUND" == true ]]; then
                echo "      - $SSH_PATH:/root/.ssh:rw  # Mount SSH keys from host (read-write)" >> "$temp_file"
            fi
            if [[ "$GIT_CONFIG_FOUND" == true ]]; then
                echo "      - $GIT_CONFIG_PATH:/root/.gitconfig:ro  # Mount git config from host" >> "$temp_file"
            fi
        fi
    done < "$compose_file"

    mv "$temp_file" "$compose_file"
    echo -e "${GREEN}✅ Updated docker-compose.yml with volume mounts${NC}"
}

# Generate SSH keys and Git config if not found
setup_missing_config() {
    echo -e "\n${YELLOW}📝 Missing configurations detected. Let's set them up...${NC}"

    # Get user input for missing configs
    local USER_NAME=""
    local USER_EMAIL=""

    if [[ "$GIT_CONFIG_FOUND" == false ]]; then
        echo -e "${BLUE}Git configuration not found.${NC}"

        read -p "Enter your full name: " USER_NAME
        read -p "Enter your email: " USER_EMAIL

        # Validate required inputs
        if [[ -z "$USER_NAME" ]]; then
            echo -e "${RED}❌ Full name is required. Exiting.${NC}"
            exit 1
        fi

        if [[ -z "$USER_EMAIL" ]]; then
            echo -e "${RED}❌ Email is required. Exiting.${NC}"
            exit 1
        fi

        echo -e "${GREEN}✅ Using: $USER_NAME <$USER_EMAIL>${NC}"
    else
        USER_NAME=$(git config --file "$GIT_CONFIG_PATH" user.name 2>/dev/null || echo "Developer")
        USER_EMAIL=$(git config --file "$GIT_CONFIG_PATH" user.email 2>/dev/null || echo "developer@localhost")
    fi

    # Create Dockerfile addition for missing configs
    if [[ "$SSH_FOUND" == false || "$GIT_CONFIG_FOUND" == false ]]; then
        local dockerfile_addon="
# Development Git and SSH setup with automation
ARG SETUP_DEV_CONFIG=true
ARG GIT_USER_NAME=\"$USER_NAME\"
ARG GIT_USER_EMAIL=\"$USER_EMAIL\"

RUN if [ \"\$SETUP_DEV_CONFIG\" = \"true\" ]; then \\"

        if [[ "$GIT_CONFIG_FOUND" == false ]]; then
            dockerfile_addon+="\n        # Setup Git configuration \\"
            dockerfile_addon+="\n        git config --global user.name \"\$GIT_USER_NAME\" && \\"
            dockerfile_addon+="\n        git config --global user.email \"\$GIT_USER_EMAIL\" && \\"
        fi

        if [[ "$SSH_FOUND" == false ]]; then
            dockerfile_addon+="\n        # Generate SSH key for development \\"
            dockerfile_addon+="\n        mkdir -p /root/.ssh && \\"
            dockerfile_addon+="\n        ssh-keygen -t ed25519 -C \"\$GIT_USER_EMAIL\" -f /root/.ssh/id_ed25519 -N \"\" && \\"
            dockerfile_addon+="\n        chmod 700 /root/.ssh && \\"
            dockerfile_addon+="\n        chmod 600 /root/.ssh/* && \\"
            dockerfile_addon+="\n        \\"
            dockerfile_addon+="\n        # Add GitHub to known_hosts \\"
            dockerfile_addon+="\n        ssh-keyscan -H github.com >> /root/.ssh/known_hosts && \\"
            dockerfile_addon+="\n        \\"
            dockerfile_addon+="\n        # Create SSH agent startup script \\"
            dockerfile_addon+="\n        echo '#!/bin/bash' > /usr/local/bin/start-ssh-agent.sh && \\"
            dockerfile_addon+="\n        echo 'eval \"\$(ssh-agent -s)\" > /dev/null' >> /usr/local/bin/start-ssh-agent.sh && \\"
            dockerfile_addon+="\n        echo 'ssh-add /root/.ssh/id_ed25519 2>/dev/null || true' >> /usr/local/bin/start-ssh-agent.sh && \\"
            dockerfile_addon+="\n        chmod +x /usr/local/bin/start-ssh-agent.sh && \\"
            dockerfile_addon+="\n        \\"
            dockerfile_addon+="\n        # Add to bashrc for automatic SSH agent \\"
            dockerfile_addon+="\n        echo 'source /usr/local/bin/start-ssh-agent.sh' >> /root/.bashrc && \\"
            dockerfile_addon+="\n        \\"
            dockerfile_addon+="\n        # Display the public key \\"
            dockerfile_addon+="\n        echo \"\n🔑 SSH key generated! Add this public key to GitHub:\" && \\"
            dockerfile_addon+="\n        echo \"==========================================\" && \\"
            dockerfile_addon+="\n        cat /root/.ssh/id_ed25519.pub && \\"
            dockerfile_addon+="\n        echo \"==========================================\"; \\"
        fi

        dockerfile_addon+="\n    fi"

        # Append to Dockerfile
        echo -e "$dockerfile_addon" >> Dockerfile
        echo -e "${GREEN}✅ Added enhanced development configuration to Dockerfile${NC}"
    fi
}

# Main execution logic
echo -e "\n${BLUE}📋 Configuration Summary:${NC}"
echo "  SSH Keys: $([ "$SSH_FOUND" = true ] && echo -e "${GREEN}Found at $SSH_PATH${NC}" || echo -e "${YELLOW}Not found${NC}")"
echo "  Git Config: $([ "$GIT_CONFIG_FOUND" = true ] && echo -e "${GREEN}Found at $GIT_CONFIG_PATH${NC}" || echo -e "${YELLOW}Not found${NC}")"

if [[ "$SSH_FOUND" == true || "$GIT_CONFIG_FOUND" == true ]]; then
    echo -e "\n${GREEN}✅ Found existing configurations - updating docker-compose.yml${NC}"
    update_docker_compose
fi

if [[ "$SSH_FOUND" == false || "$GIT_CONFIG_FOUND" == false ]]; then
    setup_missing_config
fi

# Final instructions
echo -e "\n${BLUE}🚀 Setup complete! Next steps:${NC}"
echo "1. Run: make build-dev"
echo "2. Run: make dev"

if [[ "$SSH_FOUND" == true && "$GIT_CONFIG_FOUND" == true ]]; then
    echo -e "3. ${GREEN}Your existing SSH keys and Git config will be available in the container${NC}"
elif [[ "$SSH_FOUND" == false ]]; then
    echo -e "3. ${YELLOW}SSH key will be generated during build - add the public key to GitHub${NC}"
fi

echo -e "\n${GREEN}✅ TextForensics development environment is ready for Git/SSH configuration!${NC}"
