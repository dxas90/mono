# Migration Guide: From Templates to Components

This guide explains how to migrate from the old template-based CI/CD configuration to the new component-based approach.

## What Changed?

### Old Approach (Templates)

```yaml
include:
  - local: .gitlab-ci-common.yml

stages:
  - test
  - containerize

build_python_app:
  extends: .python-test

containerize_python_app:
  extends: .containerize
  needs: [build_python_app]
```

### New Approach (Components)

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: build-python-app

  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: containerize
      job_name: containerize-app
      needs: [build-python-app]

stages:
  - test
  - containerize
```

## Migration Steps

### Step 1: Set Up the Component Project

1. Create a new GitLab project for your components (e.g., `your-group/components`)
2. Copy the `components/` directory structure to this project
3. Enable "CI/CD Catalog project" in project settings:
   - Settings → General → Visibility → CI/CD Catalog project

### Step 2: Publish Your First Release

1. Commit the component files to the repository
2. Create a `.gitlab-ci.yml` for testing (use the provided example)
3. Create a git tag with semantic versioning:

   ```bash
   git tag -a 1.0.0 -m "First release of CI/CD components"
   git push origin 1.0.0
   ```

4. The release pipeline will automatically publish to the catalog

### Step 3: Update Your Project Pipelines

Replace the old template includes with component includes:

#### Python Project

**Old:**

```yaml
include:
  - local: .gitlab-ci-python.yml
```

**New:**

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build

stages: [test, build]
```

#### Node.js Project

**Old:**

```yaml
include:
  - local: .gitlab-ci-node.yml
```

**New:**

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
    inputs:
      stage: test
      pnpm_version: "10.18.1"
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build

stages: [test, build]
```

#### Go Project

**Old:**

```yaml
include:
  - local: .gitlab-ci-go.yml
```

**New:**

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
    inputs:
      stage: test
      go_image: golang:1.25
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build

stages: [test, build]
```

## Benefits of Components

### 1. Versioning

- Pin to specific versions: `@1.0.0`
- Use partial versions: `@1.0` (latest 1.0.x)
- Use latest: `@~latest` (not recommended for production)

### 2. Discoverability

- Components appear in the GitLab CI/CD Catalog
- Searchable across your GitLab instance
- Clear documentation for each component

### 3. Inputs and Validation

- Explicit input parameters with defaults
- Better validation and error messages
- Type-safe configuration

### 4. Reusability

- Share components across projects and groups
- Version components independently
- Reduce duplication

### 5. Testing

- Test components in isolation
- Automated release pipeline
- Versioned releases ensure stability

## Custom Inputs Example

Components support flexible inputs for customization:

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: custom-test-job
      python_image: python:3.11
      requirements_file: requirements-dev.txt
      test_command: pytest --cov=src tests/
```

## Advanced Usage: Monorepo

For monorepos with multiple services:

```yaml
include:
  # Test multiple services
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: test-api-service

  - component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
    inputs:
      stage: test
      job_name: test-frontend-service

  # Build multiple images
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-api
      build_context: ./apps/api
      image_repository: $CI_REGISTRY_IMAGE/api

  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-frontend
      build_context: ./apps/frontend
      image_repository: $CI_REGISTRY_IMAGE/frontend

stages: [test, build, deploy]
```

## Best Practices

1. **Pin versions in production**: Use `@1.0.0` instead of `@~latest`
2. **Test before releasing**: Always test components in a feature branch
3. **Document changes**: Update component README when making changes
4. **Use semantic versioning**: Follow semver for releases
5. **Review component source**: Audit third-party components before use
6. **Minimize dependencies**: Keep components self-contained
7. **Use descriptive job names**: Make pipeline visualization clear

## Troubleshooting

### Component not found

Ensure the component project is set as a catalog project and has at least one published release.

### Invalid inputs

Check that all required inputs are provided and match the component's spec definition.

### Permission denied

Verify you have at least Reporter role on the component project.

## Resources

- [GitLab CI/CD Components Documentation](https://docs.gitlab.com/ci/components/)
- [CI/CD Catalog](https://docs.gitlab.com/ci/components/#cicd-catalog)
- [Component Examples](examples/)
