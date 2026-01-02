#!/bin/bash
# Simple bash script to review, merge PRs and inject repositories
# Works in CI/CD environments with GITHUB_TOKEN

set -e

echo "========================================"
echo "  Review, Merge & Inject Repositories"
echo "========================================"
echo ""

# Configuration
MOUYLENG_USER="Mouy-leng"
A69V_ORG="A6-9V"
TARGET_REPO="my-drive-projects"
WORKSPACE_ROOT="$(pwd)"
REPOS_DIR="$WORKSPACE_ROOT/injected-repos"
REPORT_PATH="$WORKSPACE_ROOT/INJECTION-REPORT.md"

# Create directory for injected repos
mkdir -p "$REPOS_DIR"

# Check for GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "[ERROR] GITHUB_TOKEN environment variable not set"
    echo "Please set GITHUB_TOKEN to proceed"
    exit 1
fi

# Function to get repositories
get_repos() {
    local owner=$1
    local type=$2
    
    echo "Fetching repositories for $owner..."
    
    if [ "$type" = "org" ]; then
        curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
             -H "Accept: application/vnd.github.v3+json" \
             "https://api.github.com/orgs/$owner/repos?per_page=100" | \
             jq -r '.[].name'
    else
        curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
             -H "Accept: application/vnd.github.v3+json" \
             "https://api.github.com/users/$owner/repos?per_page=100" | \
             jq -r '.[].name'
    fi
}

# Function to get pull requests
get_prs() {
    local owner=$1
    local repo=$2
    
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github.v3+json" \
         "https://api.github.com/repos/$owner/$repo/pulls?state=open"
}

# Function to merge pull request
merge_pr() {
    local owner=$1
    local repo=$2
    local pr_number=$3
    
    echo "    Merging PR #$pr_number..."
    
    result=$(curl -s -X PUT \
         -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github.v3+json" \
         -d '{"merge_method":"merge"}' \
         "https://api.github.com/repos/$owner/$repo/pulls/$pr_number/merge")
    
    if echo "$result" | jq -e '.merged' > /dev/null; then
        echo "      [OK] Successfully merged PR #$pr_number"
        return 0
    else
        echo "      [ERROR] Failed to merge PR #$pr_number"
        return 1
    fi
}

# Initialize report
cat > "$REPORT_PATH" << EOF
# Repository Injection Report
Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Summary

EOF

# Arrays to track results
declare -a MERGED_PRS
declare -a INJECTED_REPOS

echo ""
echo "[PHASE 1] Review and Merge Pull Requests"
echo "========================================"
echo ""

# Process Mouy-leng repositories
echo "[1/2] Processing Mouy-leng repositories..."
MOUYLENG_REPOS=$(get_repos "$MOUYLENG_USER" "user")

if [ -n "$MOUYLENG_REPOS" ]; then
    echo "$MOUYLENG_REPOS" | while read -r repo; do
        [ -z "$repo" ] && continue
        
        echo "  Repository: $MOUYLENG_USER/$repo"
        
        prs=$(get_prs "$MOUYLENG_USER" "$repo")
        pr_count=$(echo "$prs" | jq '. | length')
        
        if [ "$pr_count" -gt 0 ]; then
            echo "    [FOUND] $pr_count open PR(s)"
            
            echo "$prs" | jq -c '.[]' | while read -r pr; do
                pr_number=$(echo "$pr" | jq -r '.number')
                pr_title=$(echo "$pr" | jq -r '.title')
                mergeable=$(echo "$pr" | jq -r '.mergeable')
                
                echo "      PR #$pr_number: $pr_title"
                echo "        Mergeable: $mergeable"
                
                if [ "$mergeable" = "true" ]; then
                    if merge_pr "$MOUYLENG_USER" "$repo" "$pr_number"; then
                        MERGED_PRS+=("$MOUYLENG_USER/$repo PR#$pr_number: $pr_title")
                    fi
                else
                    echo "        [SKIP] PR is not mergeable"
                fi
            done
        else
            echo "    [OK] No open PRs"
        fi
        echo ""
    done
fi

# Process A6-9V repositories
echo "[2/2] Processing A6-9V organization repositories..."
A69V_REPOS=$(get_repos "$A69V_ORG" "org")

if [ -n "$A69V_REPOS" ]; then
    echo "$A69V_REPOS" | while read -r repo; do
        [ -z "$repo" ] && continue
        
        echo "  Repository: $A69V_ORG/$repo"
        
        prs=$(get_prs "$A69V_ORG" "$repo")
        pr_count=$(echo "$prs" | jq '. | length')
        
        if [ "$pr_count" -gt 0 ]; then
            echo "    [FOUND] $pr_count open PR(s)"
            
            echo "$prs" | jq -c '.[]' | while read -r pr; do
                pr_number=$(echo "$pr" | jq -r '.number')
                pr_title=$(echo "$pr" | jq -r '.title')
                mergeable=$(echo "$pr" | jq -r '.mergeable')
                
                echo "      PR #$pr_number: $pr_title"
                echo "        Mergeable: $mergeable"
                
                if [ "$mergeable" = "true" ]; then
                    if merge_pr "$A69V_ORG" "$repo" "$pr_number"; then
                        MERGED_PRS+=("$A69V_ORG/$repo PR#$pr_number: $pr_title")
                    fi
                else
                    echo "        [SKIP] PR is not mergeable"
                fi
            done
        else
            echo "    [OK] No open PRs"
        fi
        echo ""
    done
fi

echo ""
echo "[PHASE 2] Inject Repositories into my-drive-projects"
echo "========================================"
echo ""

# Clone and inject Mouy-leng repos
if [ -n "$MOUYLENG_REPOS" ]; then
    echo "$MOUYLENG_REPOS" | while read -r repo; do
        [ -z "$repo" ] && continue
        
        echo "  Processing: $MOUYLENG_USER/$repo"
        
        repo_path="$REPOS_DIR/$repo"
        target_path="$WORKSPACE_ROOT/$MOUYLENG_USER-$repo"
        
        # Clone or update
        if [ -d "$repo_path" ]; then
            echo "    Updating existing repository..."
            cd "$repo_path"
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
            cd "$WORKSPACE_ROOT"
        else
            echo "    Cloning repository..."
            git clone "https://x-access-token:${GITHUB_TOKEN}@github.com/$MOUYLENG_USER/$repo.git" "$repo_path" 2>/dev/null || true
        fi
        
        # Inject content
        if [ -d "$repo_path" ]; then
            echo "    Injecting content into my-drive-projects..."
            mkdir -p "$target_path"
            rsync -av --exclude='.git' "$repo_path/" "$target_path/" >/dev/null 2>&1 || \
                cp -r "$repo_path"/* "$target_path/" 2>/dev/null || true
            echo "      [OK] Content injected"
            INJECTED_REPOS+=("$MOUYLENG_USER/$repo → $MOUYLENG_USER-$repo")
        fi
        
        echo ""
    done
fi

# Clone and inject A6-9V repos
if [ -n "$A69V_REPOS" ]; then
    echo "$A69V_REPOS" | while read -r repo; do
        [ -z "$repo" ] && continue
        
        echo "  Processing: $A69V_ORG/$repo"
        
        repo_path="$REPOS_DIR/$repo"
        target_path="$WORKSPACE_ROOT/$A69V_ORG-$repo"
        
        # Clone or update
        if [ -d "$repo_path" ]; then
            echo "    Updating existing repository..."
            cd "$repo_path"
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
            cd "$WORKSPACE_ROOT"
        else
            echo "    Cloning repository..."
            git clone "https://x-access-token:${GITHUB_TOKEN}@github.com/$A69V_ORG/$repo.git" "$repo_path" 2>/dev/null || true
        fi
        
        # Inject content
        if [ -d "$repo_path" ]; then
            echo "    Injecting content into my-drive-projects..."
            mkdir -p "$target_path"
            rsync -av --exclude='.git' "$repo_path/" "$target_path/" >/dev/null 2>&1 || \
                cp -r "$repo_path"/* "$target_path/" 2>/dev/null || true
            echo "      [OK] Content injected"
            INJECTED_REPOS+=("$A69V_ORG/$repo → $A69V_ORG-$repo")
        fi
        
        echo ""
    done
fi

echo ""
echo "[PHASE 3] Commit and Push Changes"
echo "========================================"
echo ""

# Configure git
git config --global user.name "GitHub Actions"
git config --global user.email "actions@github.com"

# Add all changes
echo "Staging all changes..."
git add .

# Check for changes
if git diff --cached --quiet; then
    echo "  [INFO] No changes to commit"
else
    # Commit
    echo "Committing changes..."
    git commit -m "Inject repositories from Mouy-leng and A6-9V - $(date '+%Y-%m-%d %H:%M:%S')" || true
    
    # Push
    echo "Pushing to origin..."
    git push origin HEAD || echo "  [WARNING] Push may have had issues"
fi

# Finalize report
cat >> "$REPORT_PATH" << EOF
- **Merged Pull Requests**: ${#MERGED_PRS[@]}
- **Injected Repositories**: ${#INJECTED_REPOS[@]}

## Merged Pull Requests

EOF

if [ ${#MERGED_PRS[@]} -gt 0 ]; then
    for pr in "${MERGED_PRS[@]}"; do
        echo "- $pr" >> "$REPORT_PATH"
    done
else
    echo "- No pull requests were merged" >> "$REPORT_PATH"
fi

cat >> "$REPORT_PATH" << EOF

## Injected Repositories

EOF

if [ ${#INJECTED_REPOS[@]} -gt 0 ]; then
    for repo in "${INJECTED_REPOS[@]}"; do
        echo "- $repo" >> "$REPORT_PATH"
    done
else
    echo "- No repositories were injected" >> "$REPORT_PATH"
fi

cat >> "$REPORT_PATH" << EOF

---
*Report generated by inject-repos-simple.sh*
EOF

echo ""
echo "========================================"
echo "  Operation Complete!"
echo "========================================"
echo ""
echo "Summary:"
echo "  Merged Pull Requests: ${#MERGED_PRS[@]}"
echo "  Injected Repositories: ${#INJECTED_REPOS[@]}"
echo ""
echo "Report saved to: $REPORT_PATH"
echo ""
