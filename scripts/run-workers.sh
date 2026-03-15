#!/bin/bash

# US Citizenship Test App - Worker Orchestration Script
# Usage: ./scripts/run-workers.sh [--workers=N] [--qa]
#
# This script:
# 1. Reads tasks from docs/TODO.md
# 2. Creates worktrees for each task
# 3. Runs worker agents in parallel
# 4. Optionally runs QA after workers complete

set -e

WORKERS=${1:-1}  # Default to 1 worker, can pass --workers=N
RUN_QA=${2:-""}  # Pass --qa to run QA after workers

# Get repo root directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_NAME="$(basename "$REPO_ROOT")"
TODO_FILE="$REPO_ROOT/docs/TODO.md"
TASKS_DIR="$REPO_ROOT/docs/tasks"

# Worktrees are created as siblings to the repo
WORKTREE_BASE="$(dirname "$REPO_ROOT")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if worktrunk is available
if ! command -v wt &> /dev/null; then
    log_error "worktrunk (wt) not found. Please install it first."
    exit 1
fi

# Check if TODO.md exists
if [ ! -f "$TODO_FILE" ]; then
    log_error "$TODO_FILE not found. Create tasks there first."
    exit 1
fi

# Extract task names from TODO.md (lines with - )
extract_tasks() {
    grep -E "^\s*-\s+" "$TODO_FILE" | sed 's/.*-\s*//' | sed 's/[[:space:]]*(blocked.*//' | grep -v "^$"
}

# Check if task brief exists
task_brief_exists() {
    local task_name="$1"
    local slug=$(echo "$task_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    [ -f "$TASKS_DIR/${slug}.md" ]
}

# Create worktree and run worker for a task
run_worker_for_task() {
    local task_name="$1"
    local slug=$(echo "$task_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local branch="worker-${slug}"
    local worktree_path="$WORKTREE_BASE/$REPO_NAME.$branch"
    
    log_info "Processing task: $task_name"
    
    # Check if task brief exists
    if ! task_brief_exists "$task_name"; then
        log_warn "No task brief found for: $task_name (expected: $TASKS_DIR/${slug}.md)"
        log_warn "Skipping..."
        return 1
    fi
    
    # Create worktree (creates branch and directory)
    log_info "Creating worktree: $branch"
    
    # Remove existing worktree if it exists
    if [ -d "$worktree_path" ]; then
        log_info "Removing existing worktree: $worktree_path"
        wt remove --force "$branch" 2>/dev/null || rm -rf "$worktree_path"
        git branch -D "$branch" 2>/dev/null || true
    fi
    
    wt switch --create "$branch"
    
    # Verify worktree was created
    if [ ! -d "$worktree_path" ]; then
        log_error "Worktree not created at $worktree_path"
        return 1
    fi
    
    # Copy task brief and opencode config to worktree (exclude node_modules)
    mkdir -p "$worktree_path/docs/tasks"
    cp "$TASKS_DIR/${slug}.md" "$worktree_path/docs/tasks/"
    rsync -a --exclude='node_modules' "$REPO_ROOT/.opencode/" "$worktree_path/.opencode/"
    cp "$REPO_ROOT/AGENTS.md" "$worktree_path/" 2>/dev/null || true
    
    # Run worker agent
    log_info "Running worker agent for: $task_name"
    opencode run \
        --agent worker \
        --model github-copilot/claude-haiku-4.5 \
        --dir "$worktree_path" \
        "Implement the task described in docs/tasks/${slug}.md"
    
    # Run QA if requested
    if [ "$RUN_QA" = "--qa" ]; then
        log_info "Running QA for: $task_name"
        opencode run \
            --agent qa \
            --model github-copilot/claude-sonnet-4.6 \
            --dir "$worktree_path" \
            "Review the work done in this directory. Read docs/tasks/${slug}.md for requirements and WORKER_SUMMARY.md for context."
    fi
    
    log_info "Completed: $task_name"
    
    # Track completed tasks
    if [ $? -eq 0 ]; then
        echo "✓ $task_name" >> "$REPO_ROOT/.worktree_completed_tasks.tmp"
    else
        echo "✗ $task_name (failed)" >> "$REPO_ROOT/.worktree_completed_tasks.tmp"
    fi
}

# Main execution
main() {
    log_info "Starting worker orchestration..."
    log_info "Worktrees will be created in: $WORKTREE_BASE"
    
    # Extract tasks from TODO.md
    tasks=$(extract_tasks)
    
    if [ -z "$tasks" ]; then
        log_warn "No tasks found in $TODO_FILE"
        exit 0
    fi
    
    total=$(echo "$tasks" | wc -l)
    log_info "Found $total tasks to process"
    
    # Process each task
    current=0
    while IFS= read -r task; do
        current=$((current + 1))
        echo ""
        log_info "=== Task $current of $total ==="
        run_worker_for_task "$task" || true
    done <<< "$tasks"
    
    log_info "Worker orchestration complete!"
    log_info "Review worktrees in: $WORKTREE_BASE"
    
    # Print summary
    if [ -f "$REPO_ROOT/.worktree_completed_tasks.tmp" ]; then
        echo ""
        log_info "=== Completed Tasks ==="
        cat "$REPO_ROOT/.worktree_completed_tasks.tmp"
        rm "$REPO_ROOT/.worktree_completed_tasks.tmp"
    fi
}

main "$@"
