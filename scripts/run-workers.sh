#!/bin/bash

# US Citizenship Test App - Worker Orchestration Script
# Usage: ./scripts/run-workers.sh [--parallel] [--qa]
# 
# Environment variables:
#   MAX_PARALLEL  - Max concurrent workers (default: 5)
#
# This script:
# 1. Reads tasks from docs/TODO.md
# 2. Creates worktrees for each task
# 3. Runs worker agents (parallel or sequential, max 5 concurrent by default)
# 4. Optionally runs QA after workers complete

# Get repo root directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_NAME="$(basename "$REPO_ROOT")"
TODO_FILE="$REPO_ROOT/docs/TODO.md"
TASKS_DIR="$REPO_ROOT/docs/tasks"

# Worktrees are created as siblings to the repo
WORKTREE_BASE="$(dirname "$REPO_ROOT")"

# Max concurrent workers (configurable via env var)
MAX_PARALLEL="${MAX_PARALLEL:-5}"

# Parse arguments
RUN_PARALLEL=""
RUN_QA=""
for arg in "$@"; do
    case $arg in
        --parallel)
            RUN_PARALLEL="true"
            ;;
        --qa)
            RUN_QA="true"
            ;;
    esac
done

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
    grep -E "^\s*-\s+" "$TODO_FILE" | sed 's/^\s*-\s*//' | sed 's/[[:space:]]*(blocked.*//' | grep -v "^$"
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
    local log_file="$REPO_ROOT/.worktree_${branch}.log"
    
    log_info "Processing task: $task_name"
    
    # Check if task brief exists
    if ! task_brief_exists "$task_name"; then
        log_warn "No task brief found for: $task_name (expected: $TASKS_DIR/${slug}.md)"
        log_warn "Skipping..."
        echo "✗ $task_name (no brief)" >> "$REPO_ROOT/.worktree_completed_tasks.tmp"
        return 1
    fi
    
    # Remove existing worktree if it exists
    if [ -d "$worktree_path" ]; then
        wt remove --force "$branch" 2>/dev/null || rm -rf "$worktree_path"
        git branch -D "$branch" 2>/dev/null || true
    fi
    
    # Create worktree
    log_info "Creating worktree: $branch"
    wt switch --create "$branch" > "$log_file" 2>&1
    
    # Verify worktree was created
    if [ ! -d "$worktree_path" ]; then
        log_error "Worktree not created at $worktree_path"
        echo "✗ $task_name (worktree failed)" >> "$REPO_ROOT/.worktree_completed_tasks.tmp"
        return 1
    fi
    
    # Copy task brief and opencode config to worktree
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
        "Implement the task described in docs/tasks/${slug}.md" >> "$log_file" 2>&1
    
    local worker_status=$?
    
    # Run QA if requested
    if [ "$RUN_QA" = "true" ]; then
        log_info "Running QA for: $task_name"
        opencode run \
            --agent qa \
            --model github-copilot/claude-sonnet-4.6 \
            --dir "$worktree_path" \
            "Review the work done in this directory. Read docs/tasks/${slug}.md for requirements." >> "$log_file" 2>&1
    fi
    
    if [ $worker_status -eq 0 ]; then
        log_info "Completed: $task_name"
        echo "✓ $task_name" >> "$REPO_ROOT/.worktree_completed_tasks.tmp"
    else
        log_error "Failed: $task_name"
        echo "✗ $task_name (failed)" >> "$REPO_ROOT/.worktree_completed_tasks.tmp"
    fi
    
    return $worker_status
}

# Main execution
main() {
    log_info "Starting worker orchestration..."
    log_info "Worktrees will be created in: $WORKTREE_BASE"
    [ "$RUN_PARALLEL" = "true" ] && log_info "Mode: PARALLEL" || log_info "Mode: SEQUENTIAL"
    
    # Extract tasks from TODO.md
    tasks=$(extract_tasks)
    
    if [ -z "$tasks" ]; then
        log_warn "No tasks found in $TODO_FILE"
        exit 0
    fi
    
    # Convert to array
    task_array=()
    while IFS= read -r task; do
        task_array+=("$task")
    done <<< "$tasks"
    
    total=${#task_array[@]}
    log_info "Found $total tasks to process"
    
    # Clear completion file
    rm -f "$REPO_ROOT/.worktree_completed_tasks.tmp"
    
    if [ "$RUN_PARALLEL" = "true" ]; then
        # Run tasks in parallel with throttling
        log_info "Max concurrent workers: $MAX_PARALLEL"
        running=0
        for task in "${task_array[@]}"; do
            run_worker_for_task "$task" &
            running=$((running + 1))
            if [ $running -ge $MAX_PARALLEL ]; then
                wait -n
                running=$((running - 1))
            fi
        done
        wait
    else
        # Run tasks sequentially
        current=0
        for task in "${task_array[@]}"; do
            current=$((current + 1))
            echo ""
            log_info "=== Task $current of $total ==="
            run_worker_for_task "$task" || true
        done
    fi
    
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
