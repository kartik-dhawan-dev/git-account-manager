# Git Account Manager

## Overview
Git Account Manager is a command-line tool designed to simplify the management of multiple GitHub accounts on a single system. It provides functionality to add, switch between, and view the current GitHub account configuration, making it easier to maintain separate personal and professional GitHub identities.

## Features
- Add new GitHub accounts with associated SSH keys
- Switch between different GitHub accounts
- View current Git configuration
- Automatic SSH key generation and configuration
- Persistent configuration storage
- Store SSH keys in a dedicated subfolder (`~/.ssh/git-accounts/`)
- Backup and restore Git configurations
- Remove accounts and uninstall the tool completely

## Installation

### Pre Requisites
- Zsh shell
- Git
- SSH client
- Basic understanding of Git and SSH concepts

### Setup Steps

#### Method 1: Direct Installation
```bash
# Clone the repository
git clone https://github.com/kartik-dhawan-dev/git-account-manager.git

# Move into the directory
cd git-account-manager

# Make the script executable
chmod +x git-account.sh

# Move the script to a location in your PATH
mv git-account.sh /usr/local/bin/git-account
```

#### Method 2: Manual Setup
```bash
# Download the script
curl -o /usr/local/bin/git-account https://raw.githubusercontent.com/kartik-dhawan-dev/git-account-manager/main/git-account.sh

# Make it executable
chmod +x /usr/local/bin/git-account
```

## Usage

### Add a New Git Account
```bash
git-account add
```
Follow the prompts to enter account details.

### Switch Between Accounts
```bash
git-account switch <account_name>
```

### View Current Configuration
```bash
git-account current
```

### List Configured Accounts
```bash
git-account list
```

### Remove an Account
```bash
git-account remove
```

### Uninstall Git Account Manager
```bash
git-account uninstall
```

## Repository-Specific Configurations
To set a specific GitHub account for a repository without affecting global settings, use:
```bash
git config user.email "your-email@example.com"
git config user.name "Your GitHub Username"
git config core.sshCommand "ssh -i ~/.ssh/git-accounts/id_rsa_your_account"
```

## Troubleshooting

### SSH Key Not Recognized
Ensure your SSH key is added to the SSH agent:
```bash
ssh-add ~/.ssh/git-accounts/id_rsa_your_account
```

### Cannot Push to GitHub
Check SSH connectivity:
```bash
ssh -T git@github.com
```

### Account Not Switching
Make sure Git is using the correct SSH key:
```bash
git config --global core.sshCommand
```

## Security Considerations
- Ensure SSH keys have proper permissions:
  ```bash
  chmod 600 ~/.ssh/git-accounts/id_rsa_*
  ```
- Do not share your private SSH keys.
- Use separate keys for personal and work accounts for better security.

## Contributing

Found a bug or want to contribute? Please visit our [GitHub repository](https://github.com/kartik-dhawan-dev/git-account-manager) and submit issues or pull requests.

## License

This script is released under the MIT License. See LICENSE file for details.