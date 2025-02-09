#!/bin/zsh

# Configuration file path
CONFIG_FILE="$HOME/.git-accounts"
SSH_DIR="$HOME/.ssh"

# Subfolder for SSH keys
SSH_SUBDIR="$SSH_DIR/git-accounts"  
BACKUP_DIR="$HOME/.git-account-backup"

# Colors for output
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'

# Ensure configuration file exists
setup_initial_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo "# Git Account Configurations" > $CONFIG_FILE
        echo "# Format: account_name:email:ssh_key_name:github_username" >> $CONFIG_FILE
        echo "# Example: main:john@example.com:id_rsa_main:johnsmith" >> $CONFIG_FILE
    fi
}

validate_email() {
    local email=$1
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo "${RED}Invalid email format${NC}"
        return 1
    fi
    return 0
}

backup_git_config() {
    mkdir -p "$BACKUP_DIR"
    git config --global --list > "$BACKUP_DIR/git-config-backup.txt"
    echo "${YELLOW}Git configuration backed up to $BACKUP_DIR/git-config-backup.txt${NC}"
}


add_account() {
    echo "${BLUE}Adding new Git account${NC}"
    echo "Enter account name (e.g., main, work):"
    read account_name

    # check if account already exists
    if grep -q "^${account_name}:" "$CONFIG_FILE"; then
        echo "${RED}Account '$account_name' already exists${NC}"
        return 1
    fi

    echo "Enter email for this account:"
    read email

    # validate email
    if ! validate_email "$email"; then
        return 1
    fi

    echo "Enter GitHub username:"
    read github_username

    echo "Choose SSH key type (1: RSA, 2: ED25519):"
    read key_type
    
    case $key_type in
        1) key_type="rsa";;
        2) key_type="ed25519";;
        *) echo "${RED}Invalid choice. Using RSA by default.${NC}"; key_type="rsa";;
    esac

    # Generate SSH key in subfolder
    mkdir -p "$SSH_SUBDIR"
    chmod 700 "$SSH_SUBDIR"
    
    ssh_key_name="id_${key_type}_${account_name}"
    ssh_key_path="$SSH_SUBDIR/$ssh_key_name"
    
    ssh-keygen -t $key_type -b 4096 -C "$email" -f "$ssh_key_path"
    chmod 600 "$ssh_key_path" "$ssh_key_path.pub"

    # Add to SSH config
    if [[ ! -f "$SSH_DIR/config" ]]; then
        touch "$SSH_DIR/config"
        chmod 600 "$SSH_DIR/config"
    fi

    echo "\nHost github.com-${account_name}" >> "$SSH_DIR/config"
    echo "    HostName github.com" >> "$SSH_DIR/config"
    echo "    User git" >> "$SSH_DIR/config"
    echo "    IdentityFile ~/.ssh/git-accounts/${ssh_key_name}" >> "$SSH_DIR/config"

    # Add to config file
    echo "${account_name}:${email}:${ssh_key_name}:${github_username}" >> "$CONFIG_FILE"

    echo "${GREEN}Account added successfully!${NC}"
    echo "Please add this public key to your GitHub account:"
    cat "${ssh_key_path}.pub"
}

list_accounts() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "${RED}No accounts configured${NC}"
        return 1
    fi
    echo "${BLUE}Configured Accounts:${NC}"
    awk -F: '{print NR ". " $1 " (" $2 ")"}' "$CONFIG_FILE"
}

remove_account() {
    list_accounts || return 1

    echo "Enter the number of the account to remove:"
    read account_number

    account_line=$(sed -n "${account_number}p" "$CONFIG_FILE")

    if [[ -z "$account_line" ]]; then
        echo "${RED}Invalid selection${NC}"
        return 1
    fi

    account_name=$(echo "$account_line" | cut -d: -f1)
    ssh_key_name=$(echo "$account_line" | cut -d: -f3)

    # Remove from config file
    sed -i "/^${account_name}:/d" "$CONFIG_FILE"

    # Remove SSH keys
    rm -f "$SSH_SUBDIR/$ssh_key_name" "$SSH_SUBDIR/$ssh_key_name.pub"

    # Remove SSH config entry
    sed -i "/Host github.com-${account_name}/,/IdentityFile/d" "$SSH_DIR/config"

    echo "${GREEN}Account '$account_name' removed successfully${NC}"
}

switch_account() {
    local account_name=$1

    if [[ -z $account_name ]]; then
        echo "${RED}Please provide an account name${NC}"
        return 1
    fi

    # Find account from config
    local account_line=$(grep "^${account_name}:" "$CONFIG_FILE")

    if [[ -z $account_line ]]; then
        echo "${RED}Account '$account_name' not found${NC}"
        return 1
    fi

    # Parse account details
    local email=$(echo "$account_line" | cut -d: -f2)
    local ssh_key=$(echo "$account_line" | cut -d: -f3)
    local github_username=$(echo "$account_line" | cut -d: -f4)

    # Backup current config
    backup_git_config

    # Update Git config
    git config --global user.email "$email"
    git config --global user.name "$github_username"
    git config --global core.sshCommand "ssh -i $SSH_SUBDIR/$ssh_key"

    echo "${GREEN}Switched to account: $account_name${NC}"
    get_current_config
}

get_current_config() {
    local current_email=$(git config --global user.email)
    local current_name=$(git config --global user.name)

    echo "${BLUE}Current Git Configuration:${NC}"
    echo "Username: $current_name"
    echo "Email: $current_email"
}

uninstall() {
    echo "${YELLOW}This will remove all Git account manager configurations and SSH keys. Are you sure? (y/n)${NC}"
    read confirmation

    if [[ "$confirmation" != "y" ]]; then
        echo "${RED}Uninstallation cancelled${NC}"
        return
    fi

    rm -f "$CONFIG_FILE"

    for account_line in $(cat "$CONFIG_FILE"); do
        ssh_key_name=$(echo "$account_line" | cut -d: -f3)
        rm -f "$SSH_SUBDIR/$ssh_key_name" "$SSH_SUBDIR/$ssh_key_name.pub"
    done

    sed -i "/# Git Account Manager/d" "$SSH_DIR/config"

    rmdir "$SSH_SUBDIR" 2>/dev/null

    echo "${GREEN}Git account manager uninstalled successfully${NC}"
}

case "$1" in
    "add")
        add_account
        ;;
    "switch")
        switch_account "$2"
        ;;
    "current")
        get_current_config
        ;;
    "list")
        list_accounts
        ;;
    "remove")
        remove_account
        ;;
    "uninstall")
        uninstall
        ;;
    *)
        echo "Usage: git-account <command> [options]"
        echo "Commands:"
        echo "  add       - Add a new Git account"
        echo "  switch    - Switch to a different account (git-account switch account_name)"
        echo "  current   - Show current Git configuration"
        echo "  list      - List all configured accounts"
        echo "  remove    - Remove an account"
        echo "  uninstall - Uninstall Git account manager and remove all configurations"
        ;;
esac