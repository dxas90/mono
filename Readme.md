# Monorepo with Reusable GitLab CI/CD Components

This repository is a **production-ready monorepo** containing multiple applications with a powerful, reusable GitLab CI/CD component system. Each application can leverage shared components for testing, building, and deploying while maintaining its own independence.

## 🎯 Key Features

- 🔧 **Reusable CI/CD Components** - Shared, versioned pipeline components
- 🏗️ **Multi-Language Support** - Python, Node.js, Go, Java, PHP, Ruby
- 🚀 **Complete Workflow** - Feature → Staging → Production deployment flow
- 📦 **Git Submodules** - Isolated application repositories
- ⚡ **Performance Optimized** - Caching provides 30-70% faster builds
- 📊 **Test & Coverage Reports** - Integrated with GitLab UI
- 🔒 **Security First** - Built-in best practices and scanning
- 🌿 **Ephemeral Environments** - Feature branch preview deployments

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Getting Started](#getting-started)
3. [Applications](#applications)
4. [CI/CD Components](#cicd-components)
5. [Usage Examples](#usage-examples)
6. [Development Workflow](#development-workflow)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Architecture

### Repository Structure

```text
mono/
├── apps/                           # Application submodules
│   ├── acme-lambda-cloudflare-go/  # Go Lambda function
│   ├── django-postgresql-gunicorn/ # Django + PostgreSQL
│   ├── learn/                      # Educational app
│   ├── network-stats/              # Network monitoring
│   ├── pg-database-tester/         # PostgreSQL testing tool
│   └── sinatra-mysql-puma/         # Ruby Sinatra app
│
├── components/                     # Reusable CI/CD components
│   ├── templates/
│   │   ├── python-test/            # Python testing component
│   │   ├── node-test/              # Node.js testing component
│   │   ├── go-test/                # Go testing component
│   │   ├── java-test/              # Java testing component
│   │   ├── php-test/               # PHP testing component
│   │   ├── buildah-containerize/   # Container build component
│   │   ├── k8s-deploy/             # Kubernetes deploy component
│   │   ├── image-promote/          # Image promotion component
│   │   └── ephemeral-cleanup/      # Cleanup component
│   │
│   ├── examples/                   # Example workflows
│   │   ├── .gitlab-ci-complete-workflow.yml
│   │   ├── .gitlab-ci-simple-workflow.yml
│   │   ├── .gitlab-ci-monorepo-workflow.yml
│   │   └── .gitlab-ci-test-reports-coverage.yml
│   │
│   ├── WORKFLOW.md                 # Complete workflow guide
│   ├── SECURITY.md                 # Security best practices
│   └── README.md                   # Component documentation
│
└── .gitlab-ci.yml                  # Main pipeline configuration
```

### Component-Based Architecture

Instead of duplicating CI/CD configuration across applications, we use **GitLab CI/CD Components** - reusable, versioned pipeline building blocks that can be shared across all projects.

**Benefits**:

- ✅ **DRY Principle**: Write once, use everywhere
- ✅ **Versioning**: Components are versioned (e.g., `@1.0.0`)
- ✅ **Centralized Updates**: Fix bugs once, all apps benefit
- ✅ **Consistency**: Same patterns across all applications
- ✅ **Discoverability**: Components appear in GitLab CI/CD Catalog

---

## Getting Started

### 1. Clone the Repository

Clone with all submodules:

```bash
git clone --recurse-submodules https://gitlab.com/your-username/mono.git
cd mono
```

Or clone and initialize submodules separately:

```bash
git clone https://gitlab.com/your-username/mono.git
cd mono
git submodule init
git submodule update
```

### 2. Publish Components (First Time Setup)

To use the components in pipelines, publish them to GitLab CI/CD Catalog:

1. **Enable CI/CD Catalog** in component repository:
   - Go to **Settings → General → Visibility → CI/CD Catalog project** → Toggle ON

2. **Create first release**:

   ```bash
   cd components/
   git tag 1.0.0
   git push origin 1.0.0
   ```

3. **Verify publication**:
   - Navigate to **Explore → CI/CD Catalog** in GitLab
   - Components should appear in the catalog

### 3. Configure CI/CD Variables

Add required variables in **Settings → CI/CD → Variables**:

```text
# Container Registry (auto-provided by GitLab)
CI_REGISTRY_USER       [Protected]
CI_REGISTRY_PASSWORD   [Protected]

# Kubernetes (if using k8s-deploy)
KUBE_CONFIG           [Protected] [Masked] [File]

# Optional: NPM Packages (if needed)
NPM_TOKEN             [Protected] [Masked]
```

### 4. Create Your First Pipeline

Create `.gitlab-ci.yml` in any app:

```yaml
include:
  # Test
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      enable_cache: "true"
      enable_coverage: "true"

  # Build Container
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [python-test]

  # Deploy
  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy
      needs: [containerize]

stages:
  - test
  - build
  - deploy
```

---

## Applications

### Included Applications

| Application | Language | Description | Status |
| ----------- | -------- | ----------- | ------ |
| [acme-lambda-cloudflare-go](https://github.com/dxas90/acme-lambda-cloudflare-go.git) | Go | AWS Lambda function for Cloudflare ACME integration | Active |
| [django-postgresql-gunicorn](https://github.com/dxas90/django-postgresql-gunicorn.git) | Python | Django web app with PostgreSQL & Gunicorn | Active |
| [learn](https://github.com/dxas90/learn.git) | Various | Educational application for learning | Active |
| [network-stats](https://github.com/dxas90/network-stats.git) | Various | Network monitoring and statistics dashboard | Active |
| [pg-database-tester](https://github.com/dxas90/pg-database-tester.git) | Various | PostgreSQL database testing tool | Active |
| [sinatra-mysql-puma](https://github.com/dxas90/sinatra-mysql-puma.git) | Ruby | Sinatra web app with MySQL & Puma | Active |

### Adding New Applications

1. **Add as submodule**:

   ```bash
   git submodule add https://github.com/username/new-app.git apps/new-app
   git commit -m "Add new-app submodule"
   ```

2. **Create `.gitlab-ci.yml`** in the app using components:

   ```yaml
   include:
     - component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
       inputs:
         stage: test

   stages:
     - test
   ```

3. **Push and test**:

   ```bash
   cd apps/new-app
   git add .gitlab-ci.yml
   git commit -m "Add GitLab CI pipeline"
   git push
   ```

---

## CI/CD Components

### Available Components

#### Test Components

| Component | Language | Features |
| --------- | -------- | -------- |
| **python-test** | Python | pytest, coverage, caching, JUnit reports |
| **node-test** | Node.js | Jest/Vitest, coverage, pnpm/npm/yarn/bun |
| **go-test** | Go | go test, race detection, coverage |
| **java-test** | Java | Maven/Gradle, Jacoco, auto-detection |
| **php-test** | PHP | PHPUnit, Composer, Xdebug/PCOV |

#### Container & Deploy Components

| Component | Purpose | Features |
| --------- | ------- | -------- |
| **buildah-containerize** | Build containers | Rootless builds, TLS, auto-tagging |
| **k8s-deploy** | Deploy to Kubernetes | Ephemeral/staging/production routing |
| **image-promote** | Promote images | Fast staging→production promotion |
| **ephemeral-cleanup** | Resource cleanup | Namespace cleanup for feature branches |

### Component Documentation

Each component has comprehensive documentation:

- **README.md**: Full usage guide with examples
- **Input parameters**: All configurable options
- **Output artifacts**: What the component produces
- **Troubleshooting**: Common issues and solutions
- **Best practices**: Recommended usage patterns

See [`components/README.md`](components/README.md) for detailed documentation.

### Component Features

#### 1. Dependency Caching

All test components support caching for faster builds:

```yaml
- component: .../python-test@1.0.0
  inputs:
    enable_cache: "true"  # 40-60% faster builds
    cache_key: "$CI_COMMIT_REF_SLUG"
```

#### 2. Test Reports

Integrated with GitLab UI:

```yaml
- component: .../python-test@1.0.0
  inputs:
    enable_test_report: "true"
    enable_coverage: "true"
```

Results appear in:

- ✅ Merge Request test summary tab
- ✅ Coverage shown on changed lines in diff view
- ✅ Historical test/coverage trends

#### 3. Security

Built-in security features:

- 🔒 TLS verification enabled by default
- 🔒 Secure password handling (stdin)
- 🔒 No secret exposure in logs
- 🔒 Non-root container execution

See [`components/SECURITY.md`](components/SECURITY.md) for comprehensive security guide.

---

## Usage Examples

### Example 1: Simple Python Application

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      python_image: python:3.12
      test_command: pytest --cov=src
      enable_coverage: "true"

stages:
  - test
```

### Example 2: Node.js with Build & Deploy

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
    inputs:
      stage: test
      test_command: pnpm test

  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [node-test]

  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy
      needs: [containerize]

stages:
  - test
  - build
  - deploy
```

### Example 3: Complete Feature → Staging → Production Workflow

```yaml
include:
  # Test
  - component: .../python-test@1.0.0
    inputs:
      stage: test
      enable_coverage: "true"

  # Build
  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [python-test]

  # Deploy to ephemeral (feature branches)
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-ephemeral
      job_name: deploy-feature
      enable_ephemeral: "true"
      needs: [containerize]

  # Deploy to staging (main branch)
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-staging
      job_name: deploy-staging
      staging_namespace: staging
      enable_ephemeral: "false"
      needs: [containerize]
    rules:
      - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

  # Cleanup (manual)
  - component: .../ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup

stages:
  - test
  - build
  - deploy-ephemeral
  - deploy-staging
  - cleanup
```

### Example 4: Monorepo Multi-Service

```yaml
include:
  # Python API
  - component: .../python-test@1.0.0
    inputs:
      job_name: test-api
      test_command: cd apps/api && pytest

  - component: .../buildah-containerize@1.0.0
    inputs:
      job_name: build-api
      build_context: ./apps/api
      image_repository: $CI_REGISTRY_IMAGE/api
      needs: [test-api]

  # Node.js Frontend
  - component: .../node-test@1.0.0
    inputs:
      job_name: test-frontend
      test_command: cd apps/frontend && pnpm test

  - component: .../buildah-containerize@1.0.0
    inputs:
      job_name: build-frontend
      build_context: ./apps/frontend
      image_repository: $CI_REGISTRY_IMAGE/frontend
      needs: [test-frontend]

stages:
  - test
  - build
```

More examples in [`components/examples/`](components/examples/).

---

## Development Workflow

### Feature Branch Workflow

```text
1. Create Feature Branch
   ↓
2. Push Code
   ↓
3. Pipeline Runs:
   - Test (with caching)
   - Build container
   - Deploy to ephemeral namespace
   ↓
4. Test in ephemeral environment
   https://myapp-feature-branch.example.com
   ↓
5. Fix issues → Loop back to step 2
   ↓
6. Create Merge Request
   ↓
7. Code Review + Approval
   ↓
8. Merge to Main
   ↓
9. Staging Deployment
   https://staging.example.com
   ↓
10. Tag for Production
    git tag v1.0.0 && git push origin v1.0.0
   ↓
11. Manual Production Approval
   ↓
12. Production Deployment
    https://production.example.com
```

See [`components/WORKFLOW.md`](components/WORKFLOW.md) for detailed workflow guide.

### Working with Submodules

#### Making Changes to a Submodule

```bash
# Navigate to submodule
cd apps/django-postgresql-gunicorn

# Create feature branch
git checkout -b feature/add-api-endpoint

# Make changes
vim api/views.py

# Commit and push
git add .
git commit -m "Add new API endpoint"
git push origin feature/add-api-endpoint

# Return to main repo
cd ../..

# Update submodule reference
git add apps/django-postgresql-gunicorn
git commit -m "Update django app with new API endpoint"
git push origin main
```

#### Updating All Submodules

```bash
# Pull latest changes for all submodules
git submodule update --remote --merge

# Commit updated references
git add .
git commit -m "Update all submodules"
git push
```

#### Switching Branches in Submodules

```bash
# Switch to specific branch in submodule
cd apps/django-postgresql-gunicorn
git checkout develop
cd ../..

# Update main repo
git add apps/django-postgresql-gunicorn
git commit -m "Point to develop branch"
```

### Pipeline Optimization

#### Selective Pipeline Execution

Only run pipelines for changed apps:

```yaml
test-api:
  extends: .python-test
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      changes:
        - apps/api/**/*
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

test-frontend:
  extends: .node-test
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      changes:
        - apps/frontend/**/*
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

#### Parallel Execution

Test multiple apps in parallel:

```yaml
# All test jobs run in parallel (same stage)
test-api:
  stage: test
  # ... python test config

test-frontend:
  stage: test
  # ... node test config

test-worker:
  stage: test
  # ... go test config
```

---

## Best Practices

### 1. Component Versioning

Always pin component versions:

```yaml
# Good - specific version
- component: .../python-test@1.0.0

# Bad - no version (uses latest, unpredictable)
- component: .../python-test
```

### 2. Enable Caching

Use caching for faster builds:

```yaml
- component: .../python-test@1.0.0
  inputs:
    enable_cache: "true"  # 30-70% faster
```

### 3. Enable Test Reports

Get test results in GitLab UI:

```yaml
inputs:
  enable_test_report: "true"
  enable_coverage: "true"
```

### 4. Use Protected Variables

Store secrets in GitLab CI/CD variables, marked as **Protected** and **Masked**.

### 5. Require Manual Approval for Production

```yaml
deploy-production:
  when: manual  # Require explicit approval
  rules:
    - if: '$CI_COMMIT_TAG'
```

### 6. Regular Submodule Updates

```bash
# Weekly submodule updates
git submodule update --remote --merge
git add .
git commit -m "Weekly submodule updates"
```

### 7. Keep Components Updated

```bash
# Update component versions quarterly
# Change @1.0.0 to @1.1.0 in .gitlab-ci.yml files
```

### 8. Clean Up Ephemeral Environments

Manually trigger cleanup jobs after feature testing to free resources.

### 9. Document Application-Specific Config

Each app should have its own README explaining:

- How to run locally
- Environment variables needed
- Testing instructions
- Deployment specifics

### 10. Monitor Pipeline Performance

Review pipeline analytics:

- **CI/CD → Pipelines → Analytics**
- Look for slow jobs
- Optimize caching
- Consider parallel execution

---

## Troubleshooting

### Submodule Issues

#### Problem: Empty submodule directories

```bash
# Solution: Initialize and update
git submodule init
git submodule update
```

#### Problem: Submodule on wrong branch

```bash
# Solution: Switch to correct branch
cd apps/submodule-name
git checkout main
git pull
cd ../..
git add apps/submodule-name
git commit -m "Update submodule to main branch"
```

#### Problem: Detached HEAD in submodule

```bash
# This is normal for submodules
# To make changes, check out a branch first:
cd apps/submodule-name
git checkout -b feature-branch
```

### Component Issues

#### Problem: Component not found

```text
ERROR: Component not found: .../python-test@1.0.0
```

**Solution**: Ensure components are published to CI/CD Catalog:

1. Enable CI/CD Catalog in component repo settings
2. Create and push a git tag: `git tag 1.0.0 && git push origin 1.0.0`
3. Wait for catalog sync (~5 minutes)

#### Problem: Wrong component version

```yaml
# Update version in .gitlab-ci.yml
- component: .../python-test@1.1.0  # Update version here
```

#### Problem: Pipeline using old component version

**Solution**: Clear pipeline cache and retry, or change component version explicitly.

### Pipeline Issues

#### Problem: Tests fail but pipeline passes

**Solution**: Ensure `allow_test_failure: "false"` (default):

```yaml
- component: .../python-test@1.0.0
  inputs:
    allow_test_failure: "false"
```

#### Problem: Slow pipelines

**Solutions**:

1. Enable caching: `enable_cache: "true"`
2. Run tests in parallel (multiple jobs in same stage)
3. Use specific image tags (not `latest`)
4. Optimize Docker layers

#### Problem: Out of disk space

**Solution**: Clean up old images and containers:

```yaml
before_script:
  - docker system prune -af --volumes
```

### Deployment Issues

#### Problem: Kubernetes namespace not found

**Solution**: Create namespace manually:

```bash
kubectl create namespace staging
kubectl create namespace production
```

Ephemeral namespaces are created automatically.

#### Problem: Image pull errors

**Solution**: Create image pull secret:

```bash
kubectl create secret docker-registry gitlab-registry \
  --docker-server=$CI_REGISTRY \
  --docker-username=$CI_DEPLOY_USER \
  --docker-password=$CI_DEPLOY_PASSWORD \
  -n staging
```

### Getting Help

1. **Component Documentation**: Check [`components/`](components/) directory
   - Each component has detailed README
   - Examples in `components/examples/`
   - Security guide in `components/SECURITY.md`
   - Workflow guide in `components/WORKFLOW.md`

2. **GitLab CI/CD Docs**: <https://docs.gitlab.com/ee/ci/>

3. **Component Issues**: Open issue in component repository

4. **Application Issues**: Open issue in respective submodule repository

---

## Contributing

### Adding New Components

1. Create component in `components/templates/`:

   ```bash
   mkdir -p components/templates/my-component
   touch components/templates/my-component/template.yml
   touch components/templates/my-component/README.md
   ```

2. Define component spec in `template.yml`:

   ```yaml
   spec:
     inputs:
       stage:
         default: test
       job_name:
         default: my-job
   ---
   "$[[ inputs.job_name ]]":
     stage: $[[ inputs.stage ]]
     script:
       - echo "Hello from component"
   ```

3. Document in `README.md`

4. Test component

5. Update `components/.gitlab-ci.yml`

6. Create release tag

### Updating Components

1. Make changes to component template
2. Update component README
3. Test thoroughly
4. Create new version tag (semantic versioning)
5. Update changelog

### Coding Standards

- Follow language-specific linting rules
- Include tests for new features
- Document all configuration options
- Provide usage examples
- Follow security best practices

---

## Resources

### Documentation

- [Component Documentation](components/README.md)
- [Workflow Guide](components/WORKFLOW.md)
- [Security Guide](components/SECURITY.md)
- [Example Pipelines](components/examples/)

### External Resources

- [GitLab CI/CD Components](https://docs.gitlab.com/ee/ci/components/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Git Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## License

[Specify License]

---

## Maintainers

[List maintainers and contact information]

---

**Last Updated**: 2024-02-11
**Component Version**: 1.0.0
