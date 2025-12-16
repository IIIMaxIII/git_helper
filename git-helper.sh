#!/bin/bash
# Git Helper Script

# Get script directory and name
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
CONFIG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME}.cfg"

# Load configuration from external file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
....
    # Load configuration
    source "$CONFIG_FILE"
....
    # Build remote URL
    REMOTE_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_U
....
    # Set global git config
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"
}

# Check if we're in the repository
cd_to_repo() {
    cd "$REPO_DIR" || { echo "Error: Cannot cd to $REPO_DIR"; exit 1; }
....
    # Configure remote if not set
    if ! git remote get-url origin &>/dev/null; then
        git remote add origin "$REMOTE_URL" 2>/dev/null
    else
        git remote set-url origin "$REMOTE_URL"
    fi
}

echo

# Main script
load_config

case "$1" in
    "add")
        cd_to_repo
        if [ -z "$2" ]; then
            echo "Adding all files..."
            git add .
        else
            echo "Adding file: $2"
            git add "$2"
        fi
        git status -s
        ;;

    "commit")
        cd_to_repo
        if [ -z "$2" ]; then
            echo "Usage: $0 commit 'commit message'"
            exit 1
        fi
        echo "Committing with message: $2"
        git commit -m "$2"
        ;;

    "push")
        cd_to_repo
        echo "Pushing changes to GitHub..."
........
        # Try normal push first
        if git push origin main; then
            echo "Push successful"
        else
            echo "Push failed. Trying with force option..."
            read -p "Force push? This may overwrite remote changes! (y/N): " -n
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push --force origin main
            else
                echo "Push cancelled. Use 'git pull' first to merge remote chang
            fi
        fi
        ;;

    "pull")
        cd_to_repo
        echo "Pulling latest changes from GitHub..."
        git pull origin main
        ;;

    "status")
        cd_to_repo
        git status
        ;;

    "auto")
        # Automatic add, commit, push
        cd_to_repo
        echo "Starting automatic process..."
........
        # Check for commit message
        if [ -z "$2" ]; then
            COMMIT_MSG="Auto-commit $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Using auto-generated commit message: $COMMIT_MSG"
        else
            COMMIT_MSG="$2"
            echo "Using provided commit message: $COMMIT_MSG"
        fi
........
        # Pull first to avoid conflicts
        echo "Pulling latest changes..."
        git pull origin main
........
        git add .
        git commit -m "$COMMIT_MSG"
........
        # Push
        if git push origin main; then
            echo "Auto process completed successfully"
        else
            echo "Push failed. Trying with force..."
            read -p "Force push? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git push --force origin main
            else
                echo "Auto process completed but push failed"
            fi
        fi
        ;;

    "add-commit")
        # Add and commit
        cd_to_repo
        if [ -z "$2" ]; then
            echo "Usage: $0 add-commit 'commit message'"
            exit 1
        fi
        git add .
        git commit -m "$2"
        ;;

    "sync")
        # Full sync: pull, add, commit, push
        cd_to_repo
        echo "Starting full sync process..."
........
        # Check for commit message
        if [ -z "$2" ]; then
            COMMIT_MSG="Sync $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Using auto-generated commit message: $COMMIT_MSG"
        else
            COMMIT_MSG="$2"
            echo "Using provided commit message: $COMMIT_MSG"
        fi
........
        echo "Pulling latest changes..."
        git pull origin main
........
        echo "Adding all changes..."
        git add .
........
        echo "Committing..."
        git commit -m "$COMMIT_MSG"
........
        echo "Pushing..."
        git push origin main
........
        echo "Sync completed"
        ;;

    "log")
        cd_to_repo
        git log --oneline -10
        ;;

    "config")
        cd_to_repo
        git remote set-url origin "$REMOTE_URL"
        echo "Remote URL configured"
        git remote -v
        ;;

    "revert")
        # Revert changes
        cd_to_repo
        if [ -z "$2" ]; then
            echo "Usage: $0 revert {last|commit_hash}"
            echo ""
            echo "Options:"
            echo "  last      - Revert last commit"
            echo "  commit_hash - Revert specific commit (use hash from git log)
            echo ""
            echo "Examples:"
            echo "  $0 revert last                    # Revert last commit"
            echo "  $0 revert abc123def              # Revert specific commit"
            exit 1
        fi
........
        if [ "$2" = "last" ]; then
            echo "Reverting last commit..."
            git revert HEAD --no-edit
            echo "Last commit reverted"
        else
            echo "Reverting commit: $2"
            git revert "$2" --no-edit
            echo "Commit $2 reverted"
        fi
        ;;

    "undo")
        # Undo last commit (soft reset)
        cd_to_repo
        echo "Undoing last commit (changes will be kept in staging)..."
        git reset --soft HEAD~1
        echo "Last commit undone. Changes are staged for new commit."
        ;;

    "discard")
        # Discard uncommitted changes
        cd_to_repo
        if [ -z "$2" ]; then
            echo "Discarding all uncommitted changes..."
            git checkout -- .
            echo "All uncommitted changes discarded"
        else
            echo "Discarding file: $2"
            git checkout -- "$2"
            echo "File $2 reverted to last commit"
        fi
        ;;

    "force-push")
        # Force push without asking
        cd_to_repo
        echo "Force pushing to GitHub..."
        git push --force origin main
        echo "Force push completed"
        ;;

    *)
        echo "Git Helper Script"
        echo "================="
        echo "Usage: $0 {command} [arguments]"
        echo ""
        echo "Commands:"
        echo "  add [file]              - Add file(s) to staging"
        echo "  commit 'message'        - Commit changes"
        echo "  push                    - Push to GitHub (with force option if n
        echo "  pull                    - Pull from GitHub"
        echo "  status                  - Show status"
        echo "  auto ['message']        - Auto add+commit+push (with pull first)
        echo "  sync ['message']        - Full sync: pull, add, commit, push"
        echo "  add-commit 'message'    - Add all and commit"
        echo "  log                     - Show commit history"
        echo "  config                  - Configure remote URL"
        echo "  revert {last|hash}      - Revert a commit"
        echo "  undo                    - Undo last commit (soft reset)"
        echo "  discard [file]          - Discard uncommitted changes"
        echo "  force-push              - Force push without confirmation"
        echo ""
        echo "Examples:"
        echo "  $0 add file.txt               # Add specific file"
        echo "  $0 commit 'Fixed bug'         # Commit with message"
        echo "  $0 pull                       # Pull latest changes"
        echo "  $0 sync 'Updated files'       # Full sync with remote"
        echo "  $0 auto                       # Auto process with pull first"
        echo "  $0 auto 'Custom message'      # Auto process with custom message
        echo "  $0 revert last                # Revert last commit"
        echo "  $0 undo                       # Undo last commit"
        echo "  $0 discard                    # Discard all uncommitted changes"
        echo "  $0 force-push                 # Force push (use carefully!)"
        exit 1
        ;;
esac
echo

