# Buildah Containerize Component

Builds and pushes container images using Buildah, a rootless container building tool. Provides automatic image tagging, layer caching, parallel push, secure registry authentication, and flexible configuration.

## Features

- 🐳 **Buildah Integration**: Rootless container builds without Docker daemon
- 🏷️ **Smart Tagging**: Automatic tagging based on branch/tag/commit with additional tags support
- ⚡ **Layer Caching**: 30-60% faster builds by reusing previous image layers
- 🚀 **Parallel Push**: Push multiple tags simultaneously for faster uploads
- 🔒 **Secure by Default**: TLS verification enabled, secure password handling
- 📊 **OCI Labels**: Standard metadata labels for better image tracking
- 🔧 **Flexible Configuration**: Build args, custom isolation, compression settings
- 📦 **Build Artifacts**: Image tags exported for downstream jobs
- ⚙️ **Storage Drivers**: Configurable storage backends (vfs, overlay)

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/your-project/templates/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-container

stages:
  - build
```

## Input Parameters

### Job Configuration

| Input | Default | Required | Description |
|-------|---------|----------|-------------|
| `stage` | `containerize` | No | Pipeline stage for the build job |
| `job_name` | `containerize` | No | Name of the containerize job |
| `needs` | `[]` | No | Job dependencies |

### Image Configuration

| Input | Default | Required | Description |
|-------|---------|----------|-------------|
| `image_repository` | `$CI_REGISTRY_IMAGE` | No | Container image repository (without tag) |
| `image_tag` | (auto-computed) | No | Primary image tag (overrides auto-tagging) |

### Build Configuration

| Input | Default | Required | Description |
|-------|---------|----------|-------------|
| `dockerfile_path` | (auto-detect) | No | Path to Dockerfile |
| `containerfile_path` | (auto-detect) | No | Path to Containerfile (alternative) |
| `build_context` | `$CI_PROJECT_DIR` | No | Build context directory |
| `build_args` | `""` | No | Space-separated build arguments (e.g., 'BASE_IMAGE=python:3.10 VERSION=1.0') |

### Tagging Options

| Input | Default | Options | Description |
|-------|---------|---------|-------------|
| `auto_tag_strategy` | `auto` | `auto`, `manual` | Automatic tagging strategy |
| `additional_tags` | `""` | - | Space-separated additional tags (e.g., 'stable v1') |

**Tagging Behavior:**

- `auto`: Adds `latest` on default branch + commit SHA tags automatically
- `manual`: Only uses specified tags (primary tag + additional tags)

### Registry Configuration

| Input | Default | Required | Description |
|-------|---------|----------|-------------|
| `registry` | `$CI_REGISTRY` | No | Container registry URL |
| `registry_user` | `$CI_REGISTRY_USER` | No | Registry username |
| `registry_password` | `$CI_REGISTRY_PASSWORD` | No | Registry password |
| `tls_verify` | `true` | No | Enable TLS verification |
| `no_push` | `""` | No | Skip pushing to registry if set |

### Buildah Settings

| Input | Default | Options | Description |
|-------|---------|---------|-------------|
| `storage_driver` | `vfs` | `vfs`, `overlay` | Storage driver (vfs=simple/slower, overlay=fast/needs-fuse) |
| `buildah_format` | `docker` | `docker`, `oci` | Image format |
| `buildah_isolation` | `chroot` | `chroot`, `rootless` | Buildah isolation mode |
| `buildah_args` | `""` | - | Additional buildah bud arguments |

### Performance Options

| Input | Default | Options | Description |
|-------|---------|---------|-------------|
| `enable_layer_cache` | `true` | `true`, `false` | Enable layer caching (pulls previous image) |
| `parallel_push` | `true` | `true`, `false` | Push tags in parallel (faster) |
| `compression_level` | `6` | `0-9` | Compression level (higher=smaller/slower) |

## Output Artifacts

| Artifact | Description |
|----------|-------------|
| `build.env` | Environment file containing `IMAGE_TAG` and `VERSION` variables |

The `IMAGE_TAG` can be used in downstream jobs:

```yaml
deploy-job:
  needs: [build-container]
  before_script:
    - source build.env
  script:
    - echo "Deploying $IMAGE_TAG (version: $VERSION)"
```

## Image Tagging Strategy

The component provides flexible tagging with two strategies:

### Auto Strategy (Default)

Automatically generates tags based on Git context:

| Git Context | Tags Generated | Example |
|-------------|----------------|---------|
| Default branch (main/master) | `latest`, `<commit-sha>`, `<branch>` | `latest`, `abc123d`, `branch-main` |
| Feature branch | `branch-<sanitized>`, `<commit-sha>` | `branch-feature-auth`, `abc123d` |
| Git tag | `<tag-name>`, `<commit-sha>` | `v1.2.3`, `abc123d` |

### Manual Strategy

Only uses explicitly specified tags:

- Primary tag (from `image_tag` or computed)
- Additional tags (from `additional_tags`)

### Tag Sanitization

Branch/tag names are sanitized for Docker compatibility:

- Slashes (`/`) → dashes (`-`)
- Special characters → removed
- Lowercase conversion (tag names only)

## OCI Image Labels

All images include standard OCI labels:

```yaml
org.opencontainers.image.source=$CI_PROJECT_URL
org.opencontainers.image.revision=$CI_COMMIT_SHA
org.opencontainers.image.created=<iso8601-timestamp>
org.opencontainers.image.title=<project-name>
io.gitlab.pipeline-id=$CI_PIPELINE_ID
io.gitlab.commit-sha=$CI_COMMIT_SHA
io.gitlab.commit-ref=$CI_COMMIT_REF_NAME
```

## Complete Example

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/your-project/templates/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-api-container
      dockerfile_path: apps/api/Dockerfile
      build_context: ./apps/api
      image_repository: $CI_REGISTRY_IMAGE/api
      build_args: "VERSION=$CI_COMMIT_TAG BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      auto_tag_strategy: auto
      additional_tags: "stable production"
      enable_layer_cache: "true"
      parallel_push: "true"
      compression_level: "6"
      needs: [test-api]

stages:
  - test
  - build
```

## Advanced Examples

### Multi-Service Monorepo

Build multiple services in parallel:

```yaml
include:
  # Build API service
  - component: $CI_SERVER_FQDN/your-group/your-project/templates/buildah-containerize@1.0.0
    inputs:
      job_name: build-api
      build_context: ./apps/api
      dockerfile_path: apps/api/Dockerfile
      image_repository: $CI_REGISTRY_IMAGE/api
      enable_layer_cache: "true"

  # Build frontend service
  - component: $CI_SERVER_FQDN/your-group/your-project/templates/buildah-containerize@1.0.0
    inputs:
      job_name: build-frontend
      build_context: ./apps/frontend
      dockerfile_path: apps/frontend/Dockerfile
      image_repository: $CI_REGISTRY_IMAGE/frontend
      enable_layer_cache: "true"

  # Build worker service
  - component: $CI_SERVER_FQDN/your-group/your-project/templates/buildah-containerize@1.0.0
    inputs:
      job_name: build-worker
      build_context: ./apps/worker
      dockerfile_path: apps/worker/Dockerfile
      image_repository: $CI_REGISTRY_IMAGE/worker
      enable_layer_cache: "true"

stages:
  - build
```

### With Layer Caching and Parallel Push

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    enable_layer_cache: "true"  # Pull :latest for cache (30-60% faster)
    parallel_push: "true"        # Push all tags in parallel
    compression_level: "9"       # Maximum compression (slower but smaller)
```

### Custom Build Arguments

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    build_args: "APP_VERSION=$CI_COMMIT_TAG BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) VCS_REF=$CI_COMMIT_SHA ENVIRONMENT=production"
```

### Multiple Tags with Manual Strategy

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    auto_tag_strategy: manual
    image_tag: "v1.2.3"
    additional_tags: "stable production latest-stable"
```

### Build Without Pushing (Testing)

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    no_push: "true"  # Build only, don't push to registry
    enable_layer_cache: "false"  # No need to pull cache if not pushing
```

### Custom Image Tag

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    image_tag: "release-candidate-$CI_PIPELINE_ID"
    additional_tags: "rc-$CI_COMMIT_SHORT_SHA"
```

### Disable TLS Verification (Private Network Only)

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    tls_verify: "false"  # Only use in private/air-gapped networks
```

**⚠️ Security Warning**: Only disable TLS verification in trusted, isolated networks. This exposes you to man-in-the-middle attacks.

### Different Storage Driver

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    storage_driver: "overlay"  # Better performance, requires privileged mode
    buildah_isolation: "chroot"
```

## Integration with Other Components

### With Python Test

```yaml
include:
  - component: .../python-test@1.0.0
    inputs:
      stage: test
      job_name: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build
      needs: [test]  # Build only after tests pass

stages:
  - test
  - build
```

### With K8s Deploy

```yaml
include:
  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build

  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy
      job_name: deploy
      needs: [build]  # Deploy the built image

stages:
  - build
  - deploy
```

### Complete Workflow

```yaml
include:
  - component: .../python-test@1.0.0
    inputs:
      stage: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [python-test]

  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy
      needs: [containerize]

stages:
  - test
  - build
  - deploy
```

## Security Best Practices

### 1. Always Enable TLS Verification

```yaml
inputs:
  tls_verify: "true"  # Default, always recommended
```

### 2. Use Protected Variables for Secrets

In GitLab: **Settings → CI/CD → Variables**:

- Mark sensitive variables as **Protected** and **Masked**
- Examples: `REGISTRY_PASSWORD`, `NPM_TOKEN`, `DOCKER_AUTH_CONFIG`

### 3. Use Specific Base Images

```dockerfile
# Bad - using 'latest' tag
FROM python:latest

# Good - using specific version
FROM python:3.12.1-slim
```

### 4. Scan Images for Vulnerabilities

```yaml
scan-image:
  stage: scan
  image: aquasec/trivy:latest
  needs: [build-container]
  before_script:
    - source build.env
  script:
    - trivy image --severity HIGH,CRITICAL $IMAGE_TAG
```

### 5. Don't Commit Secrets

Never include secrets in:

- Dockerfiles
- Build arguments
- Source code

Use CI/CD variables or secret management tools instead.

## Troubleshooting

### Build Fails: Dockerfile Not Found

**Problem**: `ERROR: Dockerfile not found`

**Solution**: Specify `dockerfile_path` explicitly:

```yaml
inputs:
  dockerfile_path: path/to/Dockerfile
```

### Build Fails: Permission Denied

**Problem**: `ERROR: Permission denied`

**Solution**: Buildah runs rootless. For `overlay` storage driver, you may need:

```yaml
inputs:
  storage_driver: "vfs"  # Use vfs (slower but more compatible)
```

### Push Fails: TLS Verification Error

**Problem**: `ERROR: x509: certificate verification failed`

**Solution 1** (Recommended): Add CA certificate to runner
**Solution 2** (Not Recommended): Disable TLS only in private networks:

```yaml
inputs:
  tls_verify: "false"
```

### Push Fails: Authentication Failed

**Problem**: `ERROR: authentication required`

**Solution**: Ensure registry credentials are configured:

For GitLab Container Registry, variables are automatically set. For external registries:

```yaml
variables:
  DOCKER_AUTH_CONFIG: '{"auths":{"registry.example.com":{"auth":"base64-encoded-user:pass"}}}'
```

### Build Fails: Out of Disk Space

**Problem**: `ERROR: no space left on device`

**Solution**: Clean up old images regularly:

```yaml
before_script:
  - buildah rmi --prune
```

Or configure runner with automatic cleanup.

### NPM Install Fails During Build

**Problem**: `npm ERR! 404 Not Found - GET https://registry.npmjs.org/package`

**Solution**: Configure NPM authentication in Dockerfile:

```dockerfile
ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc
RUN npm install
RUN rm -f .npmrc
```

Pass token via build_args:

```yaml
inputs:
  build_args: "NPM_TOKEN=$NPM_TOKEN"
```

### Layer Cache Not Working

**Problem**: Builds are not faster with `enable_layer_cache: "true"`

**Solution**: Ensure previous image exists:

```yaml
inputs:
  enable_layer_cache: "true"  # Will pull :latest tag
  auto_tag_strategy: auto      # Ensure 'latest' is pushed on main branch
```

First build on a new branch won't have cache, but subsequent builds will.

### Image Tag Not Available in Downstream Jobs

**Problem**: `$IMAGE_TAG` is empty in deploy job

**Solution**: Load the `build.env` artifact:

```yaml
deploy-job:
  needs:
    - job: build-container
      artifacts: true
  before_script:
    - source build.env
    - echo "Deploying $IMAGE_TAG"
```

## Performance Tips

### 1. Enable Layer Caching

```yaml
inputs:
  enable_layer_cache: "true"  # 30-60% faster builds
```

Pulls previous image (`:latest`) and uses it as cache. First build will be slower, but subsequent builds reuse unchanged layers.

### 2. Use Parallel Push

```yaml
inputs:
  parallel_push: "true"  # Push multiple tags simultaneously
  additional_tags: "stable production"  # Benefits more with multiple tags
```

### 3. Adjust Compression Level

```yaml
inputs:
  compression_level: "3"  # Faster push, slightly larger images
  # compression_level: "9"  # Slower push, smaller images (CI/CD default: 6)
```

### 4. Use .dockerignore

Create `.dockerignore` to exclude unnecessary files:

```
.git
.gitignore
*.md
node_modules
__pycache__
*.pyc
.env
```

### 5. Optimize Dockerfile

```dockerfile
# Install dependencies first (cached layer)
COPY package.json package-lock.json ./
RUN npm install

# Copy source code last (changes frequently)
COPY . .
```

### 6. Use Multi-Stage Builds

```dockerfile
# Build stage
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

Results in smaller final images.

## Version History

- **2.0.0**: Major improvements
  - ✨ Layer caching support (30-60% faster builds)
  - ✨ Parallel push for multiple tags
  - ✨ Flexible tagging strategies (auto/manual)
  - ✨ Additional tags support
  - ✨ Build arguments support
  - ✨ OCI standard image labels
  - ✨ Compression level control
  - ✨ Better logging and progress indicators
  - 📝 Comprehensive documentation updates
  - 🐛 Improved error handling

- **1.0.0**: Initial release
  - Buildah rootless builds
  - Automatic image tagging
  - TLS verification enabled by default
  - Secure password handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
