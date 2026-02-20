# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**GitOps Monorepo** combining FluxCD-based Kubernetes deployments with Git submodule applications and reusable GitLab CI/CD component templates.

**Critical Architecture Pattern**: Apps are external Git submodules (separate repos). This monorepo only manages their GitOps deployment manifests - NOT the app source code itself.

## Repository Structure

```text
apps/         - Git submodules (learn-go, learn-python, learn-rust, mesh, ui)
                Changes to app code go to their own repos, not here
bootstrap/    - Flux CRDs + SOPS age secrets for cluster initialization
base/         - Environment-agnostic Flux HelmReleases + GitRepositories per app
overlays/     - Kustomize overlays per environment (dev/stg/prod) per app
clusters/     - Flux sync manifests per cluster type and environment
templates/    - GitLab CI/CD component templates (test, build, deploy)
scripts/      - Utility scripts (repo sync, etc.)
```

## GitOps Deployment Flow

**How apps deploy through this monorepo**:

1. App changes → Pushed to app's own repo (e.g., `dxas90/learn-go`)
2. Flux watches → `base/<app>/flux-resources.yaml` defines GitRepository + HelmRelease
3. HelmRelease → Points to `./k8s/chart` in the **app's repo** (not this monorepo)
4. Overlays patch → `overlays/<env>/<app>/kustomization.yaml` adds env-specific values
5. Clusters sync → `clusters/<provider>/<env>/gotk-sync.yaml` points to overlay path

**Example**: For learn-go in dev:

- App code: `apps/learn-go/` (submodule)
- Base: `base/learn-go/flux-resources.yaml` watches `github.com/dxas90/learn-go`
- Overlay: `overlays/dev/learn-go/kustomization.yaml` patches with dev namespace/tag
- Cluster: `clusters/kind/dev/gotk-sync.yaml` applies the dev overlay

## Common Commands

### Working with Submodules

```bash
# Clone with all submodules
git clone --recurse-submodules <repo-url>

# Update all submodules to latest
git submodule update --init --recursive --remote

# Pull changes including submodules
git pull --recurse-submodules
```

**⚠️ CRITICAL**: Never modify app code in `apps/` directly - changes won't persist. Apps have their own repos.

### Kubernetes Manifests

```bash
# Preview kustomize output before applying
kubectl kustomize base/learn-go
kubectl kustomize overlays/dev/learn-go

# Validate Flux resources
flux check --pre
kubectl apply --dry-run=server --kustomize overlays/dev/learn-go
```

### Bootstrap New Cluster

**Must be done in this exact order**:

```bash
# 1. Apply Flux controllers + CRDs
kubectl apply --kustomize bootstrap

# 2. Decrypt and apply SOPS age secret (requires age key in env)
sops exec-file "bootstrap/sops-age.sops.yaml" \
  "kubectl --namespace flux-system apply --server-side --filename {}"

# 3. Apply Flux sync for specific cluster+env
kubectl apply -f clusters/kind/gotk-sync.yaml -f clusters/kind/dev/gotk-sync.yaml

# 4. Verify reconciliation
flux check
flux get kustomizations --all-namespaces
```

### App Development (in app submodules)

Each app has a Makefile with standard targets:

```bash
# From within an app directory (apps/learn-go, etc.)
make help          # Show all available targets
make dev           # Run locally
make test          # Run tests with coverage
make build         # Build binary/assets
make docker-build  # Build container
make lint          # Run linter
```

**Language-specific testing**:

- **Go**: `go test ./...`, `go test -coverprofile=coverage.out ./...`
- **Python**: `pytest`, `pytest --cov`
- **Node/TypeScript**: `npm test`, `npm run test:e2e`
- **Rust**: `cargo test`

## GitLab CI/CD Components

**Component-based pipelines** located in `templates/`:

Available components:

- `python-test`, `node-test`, `go-test`, `java-test`, `php-test` - Language testing
- `buildah-containerize` - Rootless container builds with layer caching
- `image-promote` - Promote images between registries
- `k8s-deploy` - Kubernetes deployments
- `ephemeral-cleanup` - Cleanup temporary namespaces

Usage in app's `.gitlab-ci.yml`:

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/mono-learn/templates/go-test@1.0.0
    inputs:
      stage: test
```

**Version pinning**: Always use exact version tags (`@1.0.0`) in production pipelines.

## Kustomize Patterns

**Three-layer structure**:

1. **Base** (`base/<app>/`):
   - Contains Flux GitRepository + HelmRelease
   - Environment-agnostic labels/transformers
   - HelmRelease chart path points to **app's repo**: `./k8s/chart`

2. **Overlay** (`overlays/<env>/<app>/`):
   - References base: `resources: - ../../../base/<app>`
   - JSON patches for env-specific values (namespace, image tag, replicas)

3. **Cluster Sync** (`clusters/<provider>/<env>/`):
   - Flux Kustomization that points to overlay path
   - Applied manually to bootstrap cluster

**Pattern for editing**:

- Shared resources → Edit `base/<app>/`
- Environment-specific changes → Edit `overlays/<env>/<app>/kustomization.yaml` patches
- NEVER edit rendered manifests directly

## Secrets Management

**SOPS + age encryption**:

- Bootstrap secret: `bootstrap/sops-age.sops.yaml` (encrypted at rest)
- Configuration: `.sops.yaml` defines encryption rules
- Decrypt: `sops exec-file <file> "kubectl apply -f {}"`
- **Never commit unencrypted secrets**
- Age key must be in environment for decryption

## Tool Versions

**Managed by mise** (`mise.toml`):

- Python 3.x with automatic virtualenv (`.venv`)
- `uv` for fast Python package management

**Per-app tooling**:

- Go apps: Check `go.mod` for Go version
- Node apps: Check `.nvmrc` for Node version
- Each app manages its own dependencies

## Multi-Language Apps

Repository demonstrates polyglot patterns:

- **Go**: `apps/learn-go` - Standard lib, multi-stage Docker
- **Python**: `apps/learn-python` - Flask/Gunicorn, requirements.txt
- **Rust**: `apps/learn-rust` - Cargo workspace patterns
- **TypeScript**: `apps/mesh` - GraphQL Mesh, pnpm workspaces
- **React**: `apps/ui` - Vite, Playwright e2e tests

Each language has matching CI/CD component template in `templates/`.

## Common Pitfalls

1. **Don't modify app code in `apps/` submodules directly**
   - Changes won't persist - apps are external repos
   - Edit in app's own repository instead

2. **Don't skip `--recurse-submodules`**
   - Apps won't be present without submodule fetch

3. **Don't edit base resources for env-specific changes**
   - Use overlays with JSON patches instead

4. **HelmRelease chart path is relative to app repo**
   - Chart is in app's repo (`./k8s/chart`), not this monorepo

5. **Don't apply overlays manually in production**
   - Cluster sync manifests should reference overlays
   - Flux automatically applies and reconciles

6. **Flux resource pattern**: GitRepository watches app repo, HelmRelease deploys from it
   - Both resources are in `base/<app>/flux-resources.yaml`
   - GitRepository ignores everything except `k8s/` directory

## Key Files

- `mise.toml` - Tool version management (Python, uv)
- `.gitmodules` - Submodule definitions (app repos)
- `.sops.yaml` - SOPS encryption config (age key)
- `base/<app>/flux-resources.yaml` - Flux GitRepository + HelmRelease
- `base/<app>/labels.yaml` - Kustomize transformers for consistent labeling
- `overlays/<env>/<app>/kustomization.yaml` - Environment patches
- `clusters/<provider>/<env>/gotk-sync.yaml` - Flux Kustomization sync
- `templates/docs/ARCHITECTURE.md` - CI/CD component architecture details
- `templates/docs/WORKFLOW.md` - Complete deployment workflow

## References

Detailed documentation in:

- [bootstrap/README.md](bootstrap/README.md) - Bootstrap flow
- [clusters/README.md](clusters/README.md) - Cluster sync manifests
- [base/README.md](base/README.md) - Base resource patterns
- [overlays/README.md](overlays/README.md) - Overlay patterns
- [templates/README.md](templates/README.md) - CI/CD components
- [templates/docs/GETTING_STARTED.md](templates/docs/GETTING_STARTED.md) - Getting started guide
- [templates/docs/WORKFLOW.md](templates/docs/WORKFLOW.md) - Full deployment workflow
- [scripts/README.md](scripts/README.md) - Utility scripts
