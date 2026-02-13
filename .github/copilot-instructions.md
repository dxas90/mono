# Mono Learn - AI Agent Instructions

## Repository Architecture

This is a **GitOps monorepo** combining FluxCD Kubernetes deployments with Git submodule applications and reusable GitLab CI/CD components.

### Core Structure

```
apps/         - Git submodules (learn-go, learn-python, learn-rust, mesh, ui)
bootstrap/    - Flux CRDs + SOPS age secrets for cluster initialization
base/         - Environment-agnostic Flux HelmReleases + GitRepositories per app
overlays/     - Kustomize overlays per environment (dev/stg/prod) per app
clusters/     - Flux sync manifests per cluster type and environment
templates/    - GitLab CI/CD component templates (test, build, deploy)
```

**Critical pattern**: Apps are external Git submodules. Their source lives in separate repos but deploys through this monorepo's GitOps structure.

## GitOps Deployment Flow

1. **App changes** → Pushed to app's own repo (e.g., `dxas90/learn-go`)
2. **Flux watches** → `base/<app>/flux-resources.yaml` defines GitRepository + HelmRelease
3. **HelmRelease** → Points to `./k8s/chart` in the app's repo (not monorepo)
4. **Overlays patch** → `overlays/<env>/<app>/kustomization.yaml` adds env-specific values
5. **Clusters sync** → `clusters/<provider>/<env>/gotk-sync.yaml` points to overlay path

Example flow for learn-go in dev:
- App code in `apps/learn-go/` (git submodule)
- Base resource: `base/learn-go/flux-resources.yaml` watches `github.com/dxas90/learn-go`
- Overlay: `overlays/dev/learn-go/kustomization.yaml` patches with dev values
- Cluster: `clusters/kind/dev/gotk-sync.yaml` applies the dev overlay

## Working with Submodules

**Always use recursive operations**:
```bash
# Clone
git clone --recurse-submodules <repo-url>

# Update all submodules
git submodule update --init --recursive --remote

# Pull with submodules
git pull --recurse-submodules
```

**Modifying apps**: Changes go to the app's own repo, not this monorepo directly. This repo only updates submodule references after app releases.

## Kubernetes Manifests

**Never edit YAML in `clusters/`, `overlays/`, or `base/` without understanding kustomize**:
- `base/<app>/` contains shared resources + transformers
- `overlays/<env>/<app>/` only contains a `kustomization.yaml` that references base + patches
- Use `kubectl kustomize overlays/dev/learn-go` to preview before committing

**Flux resource pattern** (in `base/<app>/flux-resources.yaml`):
```yaml
# GitRepository watches the external app repo
kind: GitRepository
spec:
  url: https://github.com/dxas90/<app>.git
  ref:
    branch: main
  ignore: |
    /*
    !k8s/  # Only sync k8s directory from app repo
---
# HelmRelease deploys the app's k8s/chart
kind: HelmRelease
spec:
  chart:
    spec:
      chart: ./k8s/chart  # Chart lives in app repo, not monorepo
      sourceRef:
        kind: GitRepository
        name: <app>
```

## Bootstrap New Cluster

**Order matters**:
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

## GitLab CI/CD Components

**Component-based pipelines** - templates are versioned artifacts:

```yaml
# In app's .gitlab-ci.yml
include:
  - component: $CI_SERVER_FQDN/your-group/mono-learn/templates/go-test@1.0.0
    inputs:
      stage: test
```

**Available components** (see `templates/`):
- `python-test`, `node-test`, `go-test`, `java-test`, `php-test` - Language-specific testing
- `buildah-containerize` - Rootless container builds with layer caching, auto-tagging
- `image-promote` - Promote images between registries/environments
- `k8s-deploy` - Kubernetes deployments via kubectl/helm
- `ephemeral-cleanup` - Cleanup temporary namespaces

**Key patterns**:
- Components are versioned via Git tags (`@1.0.0`)
- Pin exact versions in production pipelines
- Each template has dedicated README with input parameters
- See `templates/docs/WORKFLOW.md` for feature → staging → prod flow

## App Development Workflows

Each app submodule has standardized structure:

**Go apps** (`apps/learn-go/`):
```bash
make help          # Show all targets
make dev           # Run locally
make test          # Run tests with coverage
make build         # Build binary
make docker-build  # Build container
```

**Common files per app**:
- `Makefile` - Standard targets (build, test, run, clean)
- `Dockerfile` - Multi-stage builds
- `k8s/` - Helm charts or raw manifests
- `renovate.json5` - Automated dependency updates
- `.gitlab-ci.yml` - Pipeline using monorepo components

## Secrets Management

**SOPS + age encryption**:
- Bootstrap secret: `bootstrap/sops-age.sops.yaml` (encrypted at rest)
- Decrypt with: `sops exec-file <file> "kubectl apply -f {}"`
- Never commit unencrypted secrets
- Age key required in environment for decryption

## Key Files Reference

- `mise.toml` - Tool version management (Python, Node, Go, etc.)
- `.gitmodules` - Submodule definitions
- `base/<app>/labels.yaml` - Kustomize transformers for consistent labeling
- `clusters/<provider>/<env>/cluster-vars.yaml` - Environment-specific variables
- `templates/docs/ARCHITECTURE.md` - CI/CD component architecture
- `templates/docs/WORKFLOW.md` - Complete deployment workflow guide

## Common Pitfalls

1. **Don't modify app code in `apps/` directly** - Changes won't persist. Edit in app's own repo.
2. **Don't skip `--recurse-submodules`** - Apps won't be present without submodule fetch.
3. **Don't edit base resources for env-specific changes** - Use overlays instead.
4. **Don't apply overlays without Flux** - Cluster sync manifests should reference overlays, not applied manually.
5. **HelmRelease chart path is relative to app repo** - Not this monorepo's structure.

## Testing Changes

**Preview Kustomize output**:
```bash
kubectl kustomize base/learn-go
kubectl kustomize overlays/dev/learn-go
```

**Validate Flux resources**:
```bash
flux check --pre
kubectl apply --dry-run=server --kustomize overlays/dev/learn-go
```

**Local app testing**: Use app's Makefile targets or `run-local.sh` scripts within app directories.

## Multi-Language Support

Repository demonstrates polyglot patterns:
- **Go**: `apps/learn-go` - Standard lib, multi-stage Docker, `/healthz` endpoint
- **Python**: `apps/learn-python` - Flask/Gunicorn, requirements.txt pinning
- **Rust**: `apps/learn-rust` - Cargo workspace patterns
- **TypeScript**: `apps/mesh` - GraphQL Mesh, pnpm workspaces
- **React**: `apps/ui` - Vite, Playwright e2e tests

Each stack has matching CI/CD component template for consistency.
