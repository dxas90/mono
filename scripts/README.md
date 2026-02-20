# Scripts

Utility scripts for managing the multi-repo setup.

## sync-repos.sh

Clones and updates all non-archived repositories from a GitHub organization.

### Prerequisites

- `gh` CLI installed and authenticated: `gh auth login`
- `jq` installed: `brew install jq` (macOS) or `apt install jq` (Linux)
- SSH keys configured for GitHub

### Usage

```bash
# Sync DXP repositories (default)
./scripts/sync-repos.sh

# Sync a specific organization
./scripts/sync-repos.sh hyperspace

# Sync to a custom directory
./scripts/sync-repos.sh dxp /path/to/repos

# Sync all organizations
for org in dxp hyperspace platform-mesh openmfp; do
  ./scripts/sync-repos.sh $org
done
```

### What it Does

1. **Discovers** all active (non-archived) repositories from the organization
2. **Clones** repositories that don't exist locally
3. **Updates** existing repositories (git pull)
4. **Skips** repositories with uncommitted changes
5. **Reports** summary of operations

### Example Output

```text
=== Repository Setup for 'dxp' ===
Base directory: /Users/username/git

Checking prerequisites...
✓ Prerequisites met

Fetching repository list from GitHub...
Found 87 active repositories
Skipping 12 archived repositories

Processing repositories...

[CLONE] new-service
  ✓ Cloned successfully

[UPDATE] existing-service
  ✓ Pulled 5 commit(s)

[UPDATE] another-service
  ✓ Already up to date

=== Summary ===

Total repositories: 87
✓ Newly cloned: 3
✓ Updated: 12
✓ Up to date: 71
⚠ Skipped (dirty): 1
✗ Failed: 0
📁 Archived (skipped): 12

All repositories are in: /Users/username/git/dxp/
```

### Error Handling

The script handles common issues:

- **Uncommitted changes**: Skips update, reports in summary
- **Clone failures**: Reports and continues
- **Network issues**: Retries fetch/pull operations
- **Authentication errors**: Exits with clear error message

### Tips

**Initial setup** (first time cloning all repos):

```bash
# This may take 10-30 minutes depending on org size
./scripts/sync-repos.sh dxp
```

**Daily updates** (quick):

```bash
# Usually takes 1-2 minutes
./scripts/sync-repos.sh dxp
```

**Sync multiple orgs**:

```bash
# Create a simple loop
cat > sync-all.sh <<'EOF'
#!/bin/bash
for org in dxp hyperspace platform-mesh openmfp; do
  echo "=== Syncing $org ==="
  ./scripts/sync-repos.sh $org
  echo ""
done
EOF
chmod +x sync-all.sh
./sync-all.sh
```

**Check what's out of date** without pulling:

```bash
cd ~/git/dxp/
for dir in */; do
  cd "$dir"
  git fetch --all -q 2>/dev/null
  behind=$(git rev-list HEAD..origin/$(git rev-parse --abbrev-ref HEAD) --count 2>/dev/null || echo "0")
  [ "$behind" -gt 0 ] && echo "$dir: $behind commits behind"
  cd ..
done
```

### Scheduling

Set up automatic syncing with cron:

```bash
# Edit crontab
crontab -e

# Run daily at 9 AM
0 9 * * * /path/to/claude-config/scripts/sync-repos.sh dxp >> ~/git/sync.log 2>&1

# Or use a wrapper script
cat > ~/bin/sync-all-repos.sh <<'EOF'
#!/bin/bash
cd ~/git/dxp/claude-config
for org in dxp hyperspace; do
  ./scripts/sync-repos.sh $org
done
EOF
chmod +x ~/bin/sync-all-repos.sh

# Then in crontab:
0 9 * * * ~/bin/sync-all-repos.sh >> ~/git/sync.log 2>&1
```

### Troubleshooting

**Authentication errors:**

```bash
gh auth status
gh auth login
```

**Missing jq:**

```bash
# macOS
brew install jq

# Linux
sudo apt install jq  # Debian/Ubuntu
sudo yum install jq  # RHEL/CentOS
```

**SSH key issues:**

```bash
# Test SSH connection
ssh -T git@github.com

# Add SSH key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"
gh ssh-key add ~/.ssh/id_ed25519.pub
```

**Organization access:**

```bash
# Verify you have access to the org
gh repo list <org-name> --limit 1

# Check specific repo access
gh repo view <org-name>/<repo-name>
```
