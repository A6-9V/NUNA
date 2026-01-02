#!/bin/bash

# Auto Review, Merge PRs, and Inject All Repositories
# This script automates the process of reviewing/merging all open PRs from Mouy-leng and A6-9V repos
# Then injects all repositories into the my-drive-projects repository

set -e

# Configuration
DRY_RUN=false
SKIP_MERGE=false
INJECT_ONLY=false
LOG_FILE="repo-automation-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="repo-automation-report-$(date +%Y%m%d-%H%M%S).md"
TEMP_DIR="/tmp/repo-automation-temp"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-merge)
            SKIP_MERGE=true
            shift
            ;;
        --inject-only)
            INJECT_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Color-coded logging
log_info() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
    echo -e "\033[0;36m$msg\033[0m" | tee -a "$LOG_FILE"
}

log_success() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1"
    echo -e "\033[0;32m$msg\033[0m" | tee -a "$LOG_FILE"
}

log_warning() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1"
    echo -e "\033[0;33m$msg\033[0m" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"
    echo -e "\033[0;31m$msg\033[0m" | tee -a "$LOG_FILE"
}

# Initialize report
initialize_report() {
    cat > "$REPORT_FILE" <<EOF
# Repository Automation Report
Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Summary

EOF
}

# Add section to report
add_report_section() {
    local title="$1"
    local content="$2"
    cat >> "$REPORT_FILE" <<EOF

## $title

$content

EOF
}

# Check if gh CLI is available and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed. Please install it from: https://cli.github.com/"
        return 1
    fi
    
    log_success "GitHub CLI detected: $(gh --version | head -n 1)"
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Please run: gh auth login"
        return 1
    fi
    
    log_success "GitHub CLI is authenticated"
    return 0
}

# Get all open PRs for a repository
get_repository_prs() {
    local owner="$1"
    local repo="$2"
    
    log_info "Fetching open PRs for $owner/$repo..."
    gh pr list --repo "$owner/$repo" --state open --json number,title,author,url,mergeable,statusCheckRollup --limit 100
}

# Process a single PR
process_pr() {
    local owner="$1"
    local repo="$2"
    local pr_number="$3"
    local pr_title="$4"
    local mergeable="$5"
    
    local pr_id="$owner/$repo#$pr_number"
    log_info "Processing PR: $pr_id - $pr_title"
    
    # Check if PR has conflicts
    if [ "$mergeable" = "CONFLICTING" ]; then
        log_warning "PR $pr_id has conflicts - cannot auto-merge"
        echo "Has Conflicts|Manual Review Required"
        return
    fi
    
    # Attempt to merge
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would merge PR $pr_id"
        echo "Ready to Merge|Would Merge (Dry Run)"
    else
        if gh pr merge "$pr_number" --repo "$owner/$repo" --merge --auto 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Successfully merged PR $pr_id"
            echo "Merged|Merged Successfully"
        else
            log_error "Failed to merge PR $pr_id"
            echo "Merge Failed|Failed to merge"
        fi
    fi
}

# Get user repositories
get_user_repos() {
    local username="$1"
    log_info "Fetching repositories for user: $username..."
    gh repo list "$username" --json name,url,isPrivate,updatedAt --limit 100
}

# Get organization repositories
get_org_repos() {
    local org="$1"
    log_info "Fetching repositories for organization: $org..."
    gh repo list "$org" --json name,url,isPrivate,updatedAt --limit 100
}

# Clone or update repository
sync_repository() {
    local repo_url="$1"
    local target_dir="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would sync repository: $repo_url to $target_dir"
        return 0
    fi
    
    if [ -d "$target_dir" ]; then
        log_info "Updating existing repository at $target_dir..."
        (cd "$target_dir" && git fetch --all && git pull origin HEAD)
    else
        log_info "Cloning repository to $target_dir..."
        git clone "$repo_url" "$target_dir"
    fi
    
    log_success "Successfully synced: $repo_url"
}

# Inject repository into my-drive-projects
inject_repository() {
    local source_dir="$1"
    local repo_name="$2"
    local category="$3"
    
    local target_dir="$(pwd)/injected-repos/$category/$repo_name"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would inject $repo_name into $target_dir"
        echo "$repo_name|$category|Would Inject (Dry Run)|$target_dir"
        return 0
    fi
    
    # Create target directory
    mkdir -p "$(dirname "$target_dir")"
    
    if [ -d "$source_dir" ]; then
        log_info "Injecting $repo_name into my-drive-projects..."
        
        # Copy repository contents excluding .git
        rsync -a --exclude='.git' "$source_dir/" "$target_dir/"
        
        log_success "Successfully injected: $repo_name"
        echo "$repo_name|$category|Injected Successfully|$target_dir"
    else
        log_error "Source directory not found: $source_dir"
        echo "$repo_name|$category|Source Not Found|$target_dir"
    fi
}

# Main execution
main() {
    log_info "========================================"
    log_info "Repository Automation Script Started"
    log_info "========================================"
    log_info "Dry Run: $DRY_RUN"
    log_info "Skip Merge: $SKIP_MERGE"
    log_info "Inject Only: $INJECT_ONLY"
    log_info "========================================"
    
    initialize_report
    
    # Check prerequisites
    if ! check_gh_cli; then
        log_error "GitHub CLI is not properly set up. Exiting."
        exit 1
    fi
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Arrays to store results
    declare -a pr_results
    declare -a injection_results
    
    # Phase 1: Review and Merge PRs
    if [ "$INJECT_ONLY" != true ] && [ "$SKIP_MERGE" != true ]; then
        log_info ""
        log_info "========================================"
        log_info "Phase 1: Reviewing and Merging Pull Requests"
        log_info "========================================"
        log_info ""
        
        # Process Mouy-leng repositories
        log_info "Processing Mouy-leng repositories..."
        mouy_repos=$(get_user_repos "Mouy-leng")
        
        while read -r repo; do
            repo_name=$(echo "$repo" | jq -r '.name')
            
            prs=$(get_repository_prs "Mouy-leng" "$repo_name")
            pr_count=$(echo "$prs" | jq '. | length')
            
            if [ "$pr_count" -gt 0 ]; then
                log_info "Found $pr_count open PR(s) in Mouy-leng/$repo_name"
                
                echo "$prs" | jq -c '.[]' | while read -r pr; do
                    pr_number=$(echo "$pr" | jq -r '.number')
                    pr_title=$(echo "$pr" | jq -r '.title')
                    pr_mergeable=$(echo "$pr" | jq -r '.mergeable')
                    
                    result=$(process_pr "Mouy-leng" "$repo_name" "$pr_number" "$pr_title" "$pr_mergeable")
                    pr_results+=("Mouy-leng/$repo_name|#$pr_number|$pr_title|$result")
                done
            fi
        done < <(echo "$mouy_repos" | jq -c '.[]')
        
        # Process A6-9V repositories
        log_info "Processing A6-9V repositories..."
        a6_repos=$(get_org_repos "A6-9V")
        
        while read -r repo; do
            repo_name=$(echo "$repo" | jq -r '.name')
            
            prs=$(get_repository_prs "A6-9V" "$repo_name")
            pr_count=$(echo "$prs" | jq '. | length')
            
            if [ "$pr_count" -gt 0 ]; then
                log_info "Found $pr_count open PR(s) in A6-9V/$repo_name"
                
                echo "$prs" | jq -c '.[]' | while read -r pr; do
                    pr_number=$(echo "$pr" | jq -r '.number')
                    pr_title=$(echo "$pr" | jq -r '.title')
                    pr_mergeable=$(echo "$pr" | jq -r '.mergeable')
                    
                    result=$(process_pr "A6-9V" "$repo_name" "$pr_number" "$pr_title" "$pr_mergeable")
                    pr_results+=("A6-9V/$repo_name|#$pr_number|$pr_title|$result")
                done
            fi
        done < <(echo "$a6_repos" | jq -c '.[]')
        
        # Generate PR summary
        pr_summary="### Pull Requests Processed: ${#pr_results[@]}

| Repository | PR# | Title | Status | Action |
|------------|-----|-------|--------|--------|"
        
        for result in "${pr_results[@]}"; do
            IFS='|' read -r repo pr_num title status action <<< "$result"
            pr_summary="$pr_summary
| $repo | $pr_num | $title | $status | $action |"
        done
        
        add_report_section "Pull Request Processing" "$pr_summary"
    fi
    
    # Phase 2: Clone and Inject Repositories
    log_info ""
    log_info "========================================"
    log_info "Phase 2: Cloning and Injecting Repositories"
    log_info "========================================"
    log_info ""
    
    # Inject Mouy-leng repositories
    log_info "Injecting Mouy-leng repositories..."
    mouy_repos=$(get_user_repos "Mouy-leng")
    
    while read -r repo; do
        repo_name=$(echo "$repo" | jq -r '.name')
        repo_url=$(echo "$repo" | jq -r '.url')
        
        repo_dir="$TEMP_DIR/Mouy-leng-$repo_name"
        
        if sync_repository "$repo_url" "$repo_dir"; then
            result=$(inject_repository "$repo_dir" "$repo_name" "Mouy-leng")
            injection_results+=("$result")
        fi
    done < <(echo "$mouy_repos" | jq -c '.[]')
    
    # Inject A6-9V repositories
    log_info "Injecting A6-9V repositories..."
    a6_repos=$(get_org_repos "A6-9V")
    
    while read -r repo; do
        repo_name=$(echo "$repo" | jq -r '.name')
        repo_url=$(echo "$repo" | jq -r '.url')
        
        # Skip my-drive-projects itself
        if [ "$repo_name" = "my-drive-projects" ]; then
            continue
        fi
        
        repo_dir="$TEMP_DIR/A6-9V-$repo_name"
        
        if sync_repository "$repo_url" "$repo_dir"; then
            result=$(inject_repository "$repo_dir" "$repo_name" "A6-9V")
            injection_results+=("$result")
        fi
    done < <(echo "$a6_repos" | jq -c '.[]')
    
    # Generate injection summary
    injection_summary="### Repositories Injected: ${#injection_results[@]}

| Repository | Category | Status | Target Path |
|------------|----------|--------|-------------|"
    
    for result in "${injection_results[@]}"; do
        IFS='|' read -r repo_name category status target_path <<< "$result"
        injection_summary="$injection_summary
| $repo_name | $category | $status | $target_path |"
    done
    
    add_report_section "Repository Injection" "$injection_summary"
    
    # Create index file
    if [ "$DRY_RUN" != true ]; then
        log_info "Creating repository index..."
        mkdir -p "injected-repos"
        cat > "injected-repos/README.md" <<EOF
# Injected Repositories Index
Generated: $(date '+%Y-%m-%d %H:%M:%S')

This directory contains all repositories from Mouy-leng and A6-9V that have been injected into my-drive-projects.

## Structure

- **Mouy-leng/**: Repositories from the Mouy-leng account
- **A6-9V/**: Repositories from the A6-9V organization

## Injected Repositories

$injection_summary
EOF
    fi
    
    # Final summary
    log_success ""
    log_success "========================================"
    log_success "Automation Complete!"
    log_success "========================================"
    log_info "PRs Processed: ${#pr_results[@]}"
    log_info "Repositories Injected: ${#injection_results[@]}"
    log_info "Log File: $LOG_FILE"
    log_info "Report File: $REPORT_FILE"
    log_success "========================================"
    log_success ""
}

# Run main function
main
