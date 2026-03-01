# Developer Workspace Workflows

This directory contains a suite of custom shell scripts designed to automate routine development tasks, particularly focused on Git operations and Drupal CI/CD workflows. These scripts are globally accessible via terminal aliases configured in your shell environment.

## 🚀 Installation & Setup

To use these workflows globally from any terminal window, append the following configuration to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# ==========================================
# General Terminal Aliases
# ==========================================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Git shortcuts
alias gs='git status'
alias gl='git log --oneline'
alias gp='git pull'

# Local environment tools
alias ddev-up='ddev start && ddev ssh'
alias lando-up='lando start && lando ssh'

# ==========================================
# Workflow Shortcuts
# ==========================================
# Define the root path to your custom scripts
export WF_DIR="$HOME/Projects/workspace-scripts/workflows"

alias wf-start='$WF_DIR/feature-start.sh'
alias wf-sync='$WF_DIR/sync-main.sh'
alias wf-deploy='$WF_DIR/drupal-deploy.sh'
alias wf-cex='$WF_DIR/config-export.sh'
alias wf-build='$WF_DIR/theme-build.sh'
alias wf-core='$WF_DIR/core-update.sh'
alias wf-push='$WF_DIR/feature-push.sh'
alias wf-phpcs='$WF_DIR/phpcs-check.sh'
alias wf-dbreset='$WF_DIR/db-reset.sh'
```

*Don't forget to reload your shell after updating:*

```bash
source ~/.bashrc  # For Bash
# OR
source ~/.zshrc   # For Zsh
```

---

## 🛠️ Command Reference

Once configured, the following global commands (aliases) act as wrappers for their corresponding `.sh` scripts.

| Command | Target Script | Description |
| :--- | :--- | :--- |
| **`wf-start <ID>`** | `feature-start.sh` | Creates a new feature branch from a fresh `main` branch. Expected format: `wf-start TICKET-123`. |
| **`wf-sync`** | `sync-main.sh` | Merges the latest changes from the `main` branch into your currently active branch. |
| **`wf-deploy`** | `drupal-deploy.sh` | Executes standard Drupal deployment steps: Update database (`updb`), import configurations (`cim`), and clear caches (`cr`). |
| **`wf-cex`** | `config-export.sh` | Exports Drupal configurations (`cex`) and automatically stages the `config/` directory (`git add`). |
| **`wf-build`** | `theme-build.sh` | Triggers the build process for the frontend theme (compiling assets, etc). |
| **`wf-core`** | `core-update.sh` | Initiates a Drupal core system update workflow. |
| **`wf-push`** | `feature-push.sh` | Pushes your current active branch to the remote repository. |
| **`wf-phpcs`** | `phpcs-check.sh` | Runs PHP CodeSniffer (`phpcs`) to validate code against strict Drupal coding standards. |
| **`wf-dbreset`** | `db-reset.sh` | Resets the database state (typically importing a fresh backup/dump). |

---

## ⚙️ Architecture Notes

### Shared Helpers (`wf-common.sh`)

To keep the scripts DRY (Don't Repeat Yourself), common utilities are extracted into `wf-common.sh`. This includes:

- **Execution Guards:** Validations to ensure scripts are executed in valid states (e.g., checking if the directory is a git repository).
- **Color Outputs:** Standardized colored UI logging for success, warnings, and error messages.
- **Dry-Run Mode:** Safe run executions to preview actions before making destructive changes.
