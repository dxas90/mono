# Buildah Containerize Component

Builds and pushes container images using Buildah, a rootless container building tool. Provides automatic image tagging, secure registry authentication, and flexible configuration.

## Features

- 🐳 **Buildah Integration**: Rootless container builds without Docker daemon
- 🏷️ **Automatic Tagging**: Smart tagging based on branch/tag/commit
- 🔒 **Secure by Default**: TLS verification enabled, secure password handling
- 🔧 **Flexible Configuration**: Extensive customization options
- 📦 **NPM Registry Support**: GitLab Package Registry integration
- 🚀 **Build Artifacts**: Image tags exported for downstream jobs
- ⚙️ **Storage Drivers**: Configurable storage backends (vfs, overlay)

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-container

stages:
  - build
```

## Input Parameters

| Input | Default | Required | Description |
|-------|---------|----------|-------------|
| `stage` | `containerize` | No | Pipeline stage for the build job |
| `job_name` | `containerize` | No | Name of the containerize job |
| `dockerfile_path` | (auto-detect) | No | Path to Dockerfile/Containerfile |
| `build_context` | `$CI_PROJECT_DIR` | No | Build context directory |
| `image_repository` | `$CI_REGISTRY_IMAGE` | No | Container image repository URL |
| `image_tag` | (auto-generated) | No | Custom image tag (overrides auto-tagging) |
| `buildah_args` | `""` | No | Additional buildah bud arguments |
| `build_args` | `""` | No | Docker build arguments (--build-arg) |
| `storage_driver` | `vfs` | No | Buildah storage driver (vfs, overlay, overlay2) |
| `tls_verify` | `true` | No | Enable TLS verification for registry |
| `no_push` | `""` | No | Skip pushing to registry if set to any value |
| `npm_registry_url` | `""` | No | NPM registry URL for GitLab packages |
| `npm_token` | `$NPM_TOKEN` | No | NPM authentication token |
| `rules` | (auto-detect) | No | Custom GitLab CI rules |
| `needs` | `[]` | No | Job dependencies |

## Output Artifacts

| Artifact | Description |
|----------|-------------|
| `build.env` | Environment file containing `IMAGE_TAG` variable |

The `IMAGE_TAG` can be used in downstream jobs:

```yaml
deploy-job:
  needs: [build-container]
  before_script:
    - source build.env
  script:
    - echo "Deploying $IMAGE_TAG"
```

## Image Tagging Strategy

The component automatically generates image tags based on Git context:

| Git Context | Image Tag | Example |
|-------------|-----------|---------|
| Default branch (main/master) | `latest` | `registry/image:latest` |
| Feature branch | `branch-<sanitized-name>` | `registry/image:branch-feature-auth` |
| Git tag | `<tag-name>` | `registry/image:v1.2.3` |
| Commit SHA (fallback) | `<commit-sha>` | `registry/image:abc123def456` |

Branch names are sanitized: slashes become dashes, special characters removed.

## Complete Example

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-api-container
      dockerfile_path: apps/api/Dockerfile
      build_context: ./apps/api
      image_repository: $CI_REGISTRY_IMAGE/api
      buildah_args: "--layers --force-rm"
      build_args: |
        VERSION=$CI_COMMIT_TAG
        BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      tls_verify: "true"
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
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      job_name: build-api
      build_context: ./apps/api
      dockerfile_path: apps/api/Dockerfile
      image_repository: $CI_REGISTRY_IMAGE/api

  # Build frontend service
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      job_name: build-frontend
      build_context: ./apps/frontend
      dockerfile_path: apps/frontend/Dockerfile
      image_repository: $CI_REGISTRY_IMAGE/frontend

  # Build worker service
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      job_name: build-worker
      build_context: ./apps/worker
      dockerfile_path: apps/worker/Dockerfile
      image_repository: $CI_REGISTRY_IMAGE/worker

stages:
  - build
```

### With NPM GitLab Package Registry

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    npm_registry_url: "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/npm/"
    npm_token: "$CI_JOB_TOKEN"
    build_args: |
      NPM_REGISTRY_URL=$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/npm/
      NPM_TOKEN=$CI_JOB_TOKEN
```

### Custom Build Arguments

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    build_args: |
      APP_VERSION=$CI_COMMIT_TAG
      BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      VCS_REF=$CI_COMMIT_SHA
      ENVIRONMENT=production
```

### Build Without Pushing (Testing)

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    no_push: "true"  # Build only, don't push to registry
```

### Custom Image Tag

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    image_tag: "release-candidate-$CI_PIPELINE_ID"
```

### Disable TLS Verification (Private Network Only)

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    tls_verify: "false"  # Only use in private/air-gapped networks
```

**⚠️ Security Warning**: Only disable TLS verification in trusted, isolated networks. This exposes you to man-in-the-middle attacks.

### Custom Rules

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    rules:
      - if: '$CI_COMMIT_BRANCH == "main"'
      - if: '$CI_COMMIT_TAG'
      - if: '$CI_MERGE_REQUEST_IID'
        when: manual
```

### Different Storage Driver

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    storage_driver: "overlay"  # Better performance, requires privileged mode
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

### 2. Use Protected Variables for Tokens

In GitLab: **Settings → CI/CD → Variables**:
- `NPM_TOKEN` - Mark as **Protected** and **Masked**
- `DOCKER_AUTH_CONFIG` - Mark as **Protected** and **Masked**

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

**Solution**: Ensure NPM registry variables are set:
```yaml
inputs:
  npm_registry_url: "$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/npm/"
  npm_token: "$CI_JOB_TOKEN"
```

And in Dockerfile:
```dockerfile
ARG NPM_REGISTRY_URL
ARG NPM_TOKEN
RUN npm config set registry ${NPM_REGISTRY_URL}
RUN npm config set //${NPM_REGISTRY_URL#https://}:_authToken ${NPM_TOKEN}
```

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

### 1. Use Layer Caching

```yaml
inputs:
  buildah_args: "--layers"  # Enable layer caching
```

### 2. Use .dockerignore

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

### 3. Optimize Dockerfile

```dockerfile
# Install dependencies first (cached layer)
COPY package.json package-lock.json ./
RUN npm install

# Copy source code last (changes frequently)
COPY . .
```

### 4. Use BuildKit Features

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.12-slim

# Use cache mounts
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt
```

## Version History

- **1.0.0**: Initial release
  - Buildah rootless builds
  - Automatic image tagging
  - NPM registry integration
  - TLS verification enabled by default
  - Secure password handling

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
