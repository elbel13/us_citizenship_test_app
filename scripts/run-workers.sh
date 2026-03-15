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

TODO_FILE="docs/TODO.md"
TASKS_DIR="docs/tasks"
WORKTREE_BASE=".worktrees"

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
    
    log_info "Processing task: $task_name"
    
    # Check if task brief exists
    if ! task_brief_exists "$task_name"; then
        log_warn "No task brief found for: $task_name (expected: $TASKS_DIR/${slug}.md)"
        log_warn "Skipping..."
        return 1
    fi
    
    # Create worktree
    log_info "Creating worktree: $branch"
    wt switch --create "$branch" 2>/dev/null || wt switch "$branch"
    
    # Copy task brief to worktree if it exists
    if [ -f "$TASKS_DIR/${slug}.md" ]; then
        cp "$TASKS_DIR/${slug}.md" "$WORKTREE_BASE/$branch/"
    fi
    
    # Run worker agent
    log_info "Running worker agent for: $task_name"
    opencode --agent worker --model github-copilot/claude-haiku-4.5 \
        --prompt "Implement the task described in docs/tasks/${slug}.md" \
        "$WORKTREE_BASE/$branch"
    
    # Run QA if requested
    if [ "$RUN_QA" = "--qa" ]; then
        log_info "Running QA for: $task_name"
        opencode --agent qa --model github-copilot/claude-sonnet-4.6 \
            --prompt "Review the work done in this directory. Read docs/tasks/${slug}.md for requirements and WORKER_SUMMARY.md for context." \
            "$WORKTREE_BASE/$branch"
    fi
    
    log_info "Completed: $task_name"
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
}

main "$@"
