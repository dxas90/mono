#!/bin/bash
# Repository Setup Script
# Clones and updates all non-archived repositories from a GitHub organization

set -e

# Configuration
ORG="${1:-dxp}"
BASE_DIR="${2:-$HOME/git}"
GH_HOST="${GH_HOST:-github.tools.sap}"  # Default to SAP GitHub instance
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"  # Number of parallel operations

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
total=0
cloned=0
updated=0
failed=0
skipped_archived=0
skipped_dirty=0
up_to_date=0

# Arrays for reporting
declare -a newly_cloned
declare -a updated_repos
declare -a failed_repos
declare -a dirty_repos

echo -e "${BLUE}=== Repository Setup for '$ORG' ===${NC}"
echo "Base directory: $BASE_DIR"
echo "GitHub instance: $GH_HOST"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v gh >/dev/null 2>&1; then
  echo -e "${RED}Error: gh CLI not installed${NC}"
  echo "Install: https://cli.github.com/"
  exit 1
fi

if ! gh auth status -h "$GH_HOST" >/dev/null 2>&1; then
  echo -e "${RED}Error: gh not authenticated for $GH_HOST${NC}"
  echo "Run: gh auth login -h $GH_HOST"
  exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# Create org directory
mkdir -p "$BASE_DIR/$ORG"

# Get all non-archived repos
echo "Fetching repository list from GitHub..."
repos_json=$(GH_HOST="$GH_HOST" gh repo list "$ORG" \
  --limit 1000 \
  --json name,isArchived,url 2>/dev/null || echo "[]")

if [ "$repos_json" = "[]" ]; then
  echo -e "${RED}Error: Could not fetch repositories. Check organization name and access.${NC}"
  exit 1
fi

# Parse active and archived repos - use HTTPS URL
active_repos=$(echo "$repos_json" | jq -r '.[] | select(.isArchived == false) | "\(.name)|\(.url)"')
archived_repos=$(echo "$repos_json" | jq -r '.[] | select(.isArchived == true) | .name')

total=$(echo "$active_repos" | wc -l | tr -d ' ')
skipped_archived=$(echo "$archived_repos" | grep -c "." || echo "0")

echo -e "${GREEN}Found $total active repositories${NC}"
if [ "$skipped_archived" -gt 0 ]; then
  echo -e "${YELLOW}Skipping $skipped_archived archived repositories${NC}"
fi
echo ""

# Function to process a single repo
process_repo() {
  local name=$1
  local url=$2
  local repo_path="$BASE_DIR/$ORG/$name"

  if [ ! -d "$repo_path" ]; then
    # Clone new repo
    echo -e "${YELLOW}[CLONE]${NC} $name"
    if git clone -q "$url" "$repo_path" 2>/dev/null; then
      echo -e "${GREEN}  ✓ Cloned successfully${NC}"
      echo "$name" >> /tmp/cloned_repos_$$
    else
      echo -e "${RED}  ✗ Clone failed${NC}"
      echo "$name|Clone failed" >> /tmp/failed_repos_$$
    fi
  else
    # Repo already exists - skip
    echo -e "${GREEN}[EXISTS]${NC} $name"
    echo "$name" >> /tmp/up_to_date_repos_$$
  fi
}

# Create temp files
touch /tmp/cloned_repos_$$
touch /tmp/updated_repos_$$
touch /tmp/failed_repos_$$
touch /tmp/dirty_repos_$$
touch /tmp/up_to_date_repos_$$

# Process all repos
echo "Processing repositories..."
echo ""

while IFS='|' read -r name url; do
  [ -z "$name" ] && continue
  process_repo "$name" "$url"
done <<< "$active_repos"

echo ""

# Count results
cloned=$(wc -l < /tmp/cloned_repos_$$ | tr -d ' ')
updated=$(wc -l < /tmp/updated_repos_$$ | tr -d ' ')
failed=$(wc -l < /tmp/failed_repos_$$ | tr -d ' ')
skipped_dirty=$(wc -l < /tmp/dirty_repos_$$ | tr -d ' ')
up_to_date=$(wc -l < /tmp/up_to_date_repos_$$ | tr -d ' ')

# Print summary
echo -e "${BLUE}=== Summary ===${NC}"
echo ""
echo "Total repositories: $total"
echo -e "${GREEN}✓ Newly cloned: $cloned${NC}"
echo -e "${GREEN}✓ Already exist: $up_to_date${NC}"
if [ "$skipped_dirty" -gt 0 ]; then
  echo -e "${YELLOW}⚠ Skipped (dirty): $skipped_dirty${NC}"
fi
if [ "$failed" -gt 0 ]; then
  echo -e "${RED}✗ Failed: $failed${NC}"
fi
if [ "$skipped_archived" -gt 0 ]; then
  echo -e "${YELLOW}📁 Archived (skipped): $skipped_archived${NC}"
fi
echo ""

# Detailed lists
if [ "$cloned" -gt 0 ]; then
  echo -e "${GREEN}Newly Cloned:${NC}"
  while read -r repo; do
    [ -z "$repo" ] && continue
    echo "  - $repo"
  done < /tmp/cloned_repos_$$
  echo ""
fi

if [ "$failed" -gt 0 ]; then
  echo -e "${RED}Failed:${NC}"
  while IFS='|' read -r repo reason; do
    [ -z "$repo" ] && continue
    echo "  - $repo ($reason)"
  done < /tmp/failed_repos_$$
  echo ""
fi

# Cleanup
rm -f /tmp/cloned_repos_$$ /tmp/updated_repos_$$ /tmp/failed_repos_$$ /tmp/dirty_repos_$$ /tmp/up_to_date_repos_$$

echo -e "${GREEN}All repositories are in: $BASE_DIR/$ORG/${NC}"
echo ""

# Next steps
if [ "$cloned" -gt 0 ] || [ "$updated" -gt 0 ]; then
  echo -e "${BLUE}Next steps:${NC}"
  if [ ! -L "$HOME/.claude/agents" ]; then
    echo "  1. Link agents: ln -s $BASE_DIR/$ORG/claude-config/agents ~/.claude/agents"
  fi
  echo "  2. Start using: cd $BASE_DIR/$ORG/<repo-name> && claude chat"
fi
