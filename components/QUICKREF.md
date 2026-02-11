# GitLab CI/CD Components - Quick Reference

## Component Usage Syntax

```yaml
include:
  - component: $CI_SERVER_FQDN/<group>/<project>/<component-name>@<version>
    inputs:
      input_name: value
```

## Available Components

### Build & Test Components

#### Python Test

```yaml
- component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
  inputs:
    stage: test
    job_name: test-python
    python_image: python:3.12
    requirements_file: requirements.txt
    test_command: pytest
```

#### Node.js Test

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    stage: test
    job_name: test-node
    node_image: node:22-alpine
    pnpm_version: "10.18.1"
    test_command: pnpm test
```

#### Go Test

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    stage: test
    job_name: test-go
    go_image: golang:1.25
    build_flags: "-v"
    test_flags: "-v -race"
```

#### Java Test

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    stage: test
    job_name: test-java
    java_image: eclipse-temurin:21-jdk
    build_tool: auto  # or maven, gradle
```

#### PHP Test

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    stage: test
    job_name: test-php
    php_image: php:8.3
    test_command: ./vendor/bin/phpunit
```

### Container Components

#### Buildah Containerize

```yaml
- component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
  inputs:
    stage: containerize
    job_name: build-image
    dockerfile_path: Dockerfile          # optional, auto-detected
    build_context: $CI_PROJECT_DIR
    image_repository: $CI_REGISTRY_IMAGE
    buildah_args: "--build-arg KEY=VALUE"
    no_push: ""                          # set to skip push
```

**Outputs:**

- `build.env` with `IMAGE_TAG` variable

#### Image Promote

```yaml
- component: $CI_SERVER_FQDN/your-group/components/image-promote@1.0.0
  inputs:
    stage: promote
    job_name: promote-image
    source_tag: $IMAGE_TAG
    target_tag: production
```

**Outputs:**

- `buildah-promotion.env` with `PROMOTED_IMAGE` variable

### Deployment Components

#### Kubernetes Deploy

```yaml
- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    stage: deploy
    job_name: deploy-app
    k8s_manifest_path: k8s/deployment.yaml
    ephemeral_namespace: $CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG
    staging_namespace: staging
    production_namespace: production
    enable_ephemeral: "true"
```

**Behavior:**

- Feature branches → Ephemeral namespace
- Main branch → Staging namespace
- Tags → Production namespace

#### Ephemeral Cleanup

```yaml
- component: $CI_SERVER_FQDN/your-group/components/ephemeral-cleanup@1.0.0
  inputs:
    stage: cleanup
    job_name: cleanup
    ephemeral_namespace: $CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG
```

**Trigger:** Manual action on feature branches

### Utility Components

#### Notify

```yaml
- component: $CI_SERVER_FQDN/your-group/components/notify@1.0.0
  inputs:
    stage: notify
    message: "Deployment completed"
```

## Version Selection

| Syntax | Description | Example |
|--------|-------------|---------|
| `@1.0.0` | Exact version | `@1.0.0` |
| `@1.0` | Latest 1.0.x | `@1.0` → `1.0.5` |
| `@1` | Latest 1.x.x | `@1` → `1.2.3` |
| `@~latest` | Latest release | Not recommended |
| `@$CI_COMMIT_SHA` | Specific commit | For testing |
| `@main` | Branch name | For testing |

## Common Patterns

### Simple Pipeline

```yaml
include:
  - component: $CI_SERVER_FQDN/group/components/python-test@1.0.0
    inputs:
      stage: test
  - component: $CI_SERVER_FQDN/group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [test-python]

stages: [test, build]
```

### Full Production Pipeline

```yaml
include:
  - component: $CI_SERVER_FQDN/group/components/go-test@1.0.0
    inputs:
      stage: test
  - component: $CI_SERVER_FQDN/group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [test-go]
  - component: $CI_SERVER_FQDN/group/components/image-promote@1.0.0
    inputs:
      stage: promote
      target_tag: stable
  - component: $CI_SERVER_FQDN/group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy

stages: [test, build, promote, deploy]
```

### Monorepo with Multiple Services

```yaml
include:
  # Service 1
  - component: $CI_SERVER_FQDN/group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: test-api
  - component: $CI_SERVER_FQDN/group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-api
      build_context: ./apps/api
      image_repository: $CI_REGISTRY_IMAGE/api

  # Service 2
  - component: $CI_SERVER_FQDN/group/components/node-test@1.0.0
    inputs:
      stage: test
      job_name: test-frontend
  - component: $CI_SERVER_FQDN/group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-frontend
      build_context: ./apps/frontend
      image_repository: $CI_REGISTRY_IMAGE/frontend

stages: [test, build, deploy]
```

## Environment Variables

### Automatically Available

- `$CI_SERVER_FQDN` - GitLab instance FQDN
- `$CI_PROJECT_PATH` - Current project path
- `$CI_COMMIT_SHA` - Current commit SHA
- `$CI_COMMIT_TAG` - Tag name (if tagged)
- `$CI_COMMIT_BRANCH` - Branch name
- `$CI_COMMIT_REF_SLUG` - Sanitized branch/tag name
- `$CI_DEFAULT_BRANCH` - Default branch (usually main)
- `$CI_REGISTRY` - Container registry URL
- `$CI_REGISTRY_IMAGE` - Full image path
- `$CI_REGISTRY_USER` - Registry username
- `$CI_REGISTRY_PASSWORD` - Registry password

### Component Outputs

- `IMAGE_TAG` - Built image tag (from buildah-containerize)
- `PROMOTED_IMAGE` - Promoted image tag (from image-promote)

## Troubleshooting

### Component not found

```
Error: Component 'gitlab.com/group/components/my-component@1.0.0' - content not found
```

**Solutions:**

1. Verify component project is set as catalog project
2. Ensure at least one release is published
3. Check component name matches directory/file structure
4. Verify you have access to the component project

### Invalid version

```
Error: Version '1.0' not found
```

**Solutions:**

1. Check that a release with that version exists
2. Use full semantic version for unpublished components
3. Verify component is published to catalog

### Missing inputs

```
Error: Required input 'stage' not provided
```

**Solutions:**

1. Check component's spec section for required inputs
2. Provide all required inputs in your include
3. Review component documentation

### Permission denied

```
Error: Permission denied accessing component
```

**Solutions:**

1. Verify you have at least Reporter role on component project
2. Check if component project is in a group you can access
3. For private components, ensure proper group membership

## Tips

1. **Always pin versions in production**: `@1.0.0` not `@~latest`
2. **Use partial versions for non-critical**: `@1` for dev environments
3. **Test components in feature branches**: Use `@$CI_COMMIT_SHA`
4. **Review component before using**: Check source code in repository
5. **Use job dependencies**: Connect jobs with `needs` input
6. **Customize job names**: Avoid conflicts in complex pipelines
7. **Check artifacts**: Components may produce useful artifacts

## Quick Setup Checklist

- [ ] Create component project in GitLab
- [ ] Copy components to `templates/` directory
- [ ] Add `README.md` with documentation
- [ ] Add `LICENSE.md` file
- [ ] Create `.gitlab-ci.yml` for testing
- [ ] Enable "CI/CD Catalog project" in settings
- [ ] Test components locally
- [ ] Create semantic version tag (e.g., `1.0.0`)
- [ ] Verify release is created automatically
- [ ] Check component appears in CI/CD Catalog
- [ ] Update project pipelines to use components

## Resources

- [Component Project](components/)
- [Migration Guide](components/MIGRATION.md)
- [Examples](components/examples/)
- [GitLab Docs](https://docs.gitlab.com/ci/components/)
