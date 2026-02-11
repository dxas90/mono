# Complete Workflow Implementation Guide

This guide shows you how to implement the **Feature → Staging → Production** deployment workflow using GitLab CI/CD components.

## Workflow Diagram

```text
   +-------------------------+       +-----------------+
+-►| Create a Feature Branch |   +--►| Build Container |
|  +------------+------------+   |   +--------+--------+
|               |                |            |
|               |                |            |
|      +--------▼--------+       |    +-------▼--------+
|  +--►+ Push the Branch +-------+    | Push Container |
|  |   +--------+--------+            +-------+--------+
|  |            |                             |
|  |            |                             |
|  |     +------▼------+            +---------▼-----------+
|  +-----+ Test/Verify +◄-------+   | Deploy Container to |
|        +------+------+        |   | Ephemeral Namespace |
|               |               |   +---------+-----------+
|               |               |             |
|               |               +-------------+
|               |
|               |
|               |                    +-----------------+
|               |             +-----►| Build Container |
|      +--------▼--------+    |      +--------+--------+
|  +--►+ Merge to Master +----+               |
|  |   +--------+--------+                    |
|  |            |                     +-------▼--------+
|  |            |                     | Push Container |
|  |     +------▼------+              +-------+--------+
|  +-----+ Test/Verify +◄------+              |
|        +------+------+       |              |
|               |              |    +---------▼-----------+
|               |              |    | Deploy Container to |
|               |              |    | Staging   Namespace |
|               |              |    +---------+-----------+
|               |              |              |
|               |              +--------------+
|               |
|        +------▼-----+             +---------------------+
+--------+ Tag Master +------------►| Deploy Container to |
         +------------+             |     Production      |
                                    +---------------------+
```

## Table of Contents

1. [Phase 1: Feature Branch Development](#phase-1-feature-branch-development)
2. [Phase 2: Merge to Main/Staging](#phase-2-merge-to-main-staging)
3. [Phase 3: Production Deployment](#phase-3-production-deployment)
4. [Setup Instructions](#setup-instructions)
5. [Troubleshooting](#troubleshooting)

---

## Phase 1: Feature Branch Development

### Flow

1. Create feature branch
2. Push code
3. **Test** → **Build** → **Deploy to Ephemeral** → **Verify**
4. Fix issues and loop back to step 2

### What Happens

```yaml
# feature-branch push triggers:

1. test-application
   ├─ Runs pytest with coverage
   ├─ Uses cached dependencies (30-70% faster)
   └─ ✓ Tests pass

2. build-container
   ├─ Builds Docker image with Buildah
   ├─ Tags: $CI_REGISTRY_IMAGE:feature-amazing-stuff
   ├─ Pushes to GitLab Container Registry
   └─ ✓ Build complete

3. deploy-feature
   ├─ Creates namespace: myapp-feature-amazing-stuff
   ├─ Deploys container to ephemeral namespace
   ├─ Sets up service/ingress
   └─ ✓ Deployed to https://myapp-feature-amazing-stuff.staging.example.com

4. verify-ephemeral
   ├─ Runs health checks
   ├─ Runs smoke tests
   └─ ✓ Environment ready for testing
```

### Developer Experience

```bash
# Create feature branch
git checkout -b feature/amazing-stuff

# Make changes
vim src/api.py

# Push (triggers pipeline)
git push origin feature/amazing-stuff

# ⚡ Pipeline runs automatically:
# ✓ Tests (2 min with cache)
# ✓ Build (1 min)
# ✓ Deploy to ephemeral (30 sec)
# ✓ Verify (10 sec)
#
# 🌐 Environment URL: https://myapp-feature-amazing-stuff.staging.example.com

# Test the feature, find a bug, fix it
vim src/api.py
git commit -am "Fix bug"
git push

# ⚡ Pipeline runs again automatically (faster due to cache)
# Loop continues until feature is ready
```

### Benefits

- **Isolated Testing**: Each branch gets its own namespace
- **Fast Feedback**: Cached dependencies speed up iterations
- **No Conflicts**: Multiple developers can test simultaneously
- **Easy Cleanup**: Delete branch → Cleanup job removes namespace

---

## Phase 2: Merge to Main (Staging)

### Flow

1. Create merge request
2. Review & merge to main
3. **Test** → **Build** → **Deploy to Staging** → **Verify**
4. If issues found, create hotfix and loop back

### What Happens

```yaml
# main branch push triggers:

1. test-application
   ├─ Runs full test suite
   ├─ Uses cached dependencies
   └─ ✓ Tests pass

2. build-container
   ├─ Builds Docker image
   ├─ Tags: $CI_REGISTRY_IMAGE:latest
   ├─ Pushes to registry
   └─ ✓ Build complete

3. deploy-staging
   ├─ Deploys to staging namespace
   ├─ Updates existing deployment
   ├─ Waits for rollout to complete
   └─ ✓ Deployed to https://staging.example.com

4. verify-staging
   ├─ Runs comprehensive integration tests
   ├─ Runs performance tests
   ├─ Runs security scans
   └─ ✓ Staging verification complete
```

### Developer Experience

```bash
# Feature is ready, create MR
git checkout feature/amazing-stuff
git push origin feature/amazing-stuff

# In GitLab UI:
# 1. Create Merge Request
# 2. Code review happens
# 3. Approve & Merge

# ⚡ Main pipeline runs:
# ✓ Tests (2 min)
# ✓ Build (1 min)
# ✓ Deploy to Staging (30 sec)
# ✓ Integration Tests (5 min)
#
# 🌐 Staging URL: https://staging.example.com
# ✅ Ready to tag for production
```

### Benefits

- **Production-like Testing**: Staging mimics production
- **Integration Validation**: All features tested together
- **Confidence**: Comprehensive test coverage before prod
- **Rollback Safety**: Can quickly revert if issues found

---

## Phase 3: Production Deployment

### Flow

1. Tag the main branch
2. **Deploy to Production** (manual approval)
3. **Verify Production**
4. Monitor and celebrate 🎉

### What Happens

```yaml
# git tag triggers:

1. deploy-production (manual)
   ├─ Uses image: $CI_REGISTRY_IMAGE:v1.2.3
   ├─ Updates production deployment
   ├─ Waits for rollout to complete
   ├─ Zero-downtime deployment
   └─ ✓ Deployed to https://production.example.com

2. verify-production
   ├─ Runs production smoke tests
   ├─ Verifies all critical paths
   ├─ Checks metrics and logs
   └─ ✓ Production healthy
```

### Developer Experience

```bash
# Staging is tested and approved, tag for production
git checkout main
git pull origin main

# Create semantic version tag
git tag v1.2.3
git push origin v1.2.3

# ⚡ Pipeline triggers:
#
# Job: deploy-production (⏸️ Manual - requires approval)
#
# In GitLab UI:
# 1. Go to Pipelines → Running pipeline
# 2. Review deployment details
# 3. Click "deploy-production" → ▶️ Play
#
# ✓ Deploying v1.2.3 to production
# ✓ Rolling update in progress
# ✓ New pods healthy
# ✓ Old pods terminated
# ✓ Verify production (automatic)
#
# 🌐 Production URL: https://production.example.com
# 🎉 v1.2.3 is live!
```

### Benefits

- **Manual Approval**: Production requires explicit approval
- **Version Tracking**: Git tags track what's in production
- **Rollback Easy**: Previous tags can be re-deployed
- **Audit Trail**: Full deployment history in GitLab

---

## Setup Instructions

### 1. Publish Components to GitLab

```bash
# In your components repository
cd /path/to/components

# Enable CI/CD Catalog in GitLab:
# Settings → General → CI/CD Catalog project → ON

# Create first release
git tag 1.0.0
git push origin 1.0.0

# Pipeline runs and publishes components
# Verify in GitLab: Explore → CI/CD Catalog
```

### 2. Configure Your Application Repository

Create `.gitlab-ci.yml` in your application repo:

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: test

  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build
      needs: [test]

  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy-ephemeral
      job_name: deploy-feature
      needs: [build]

  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy-staging
      job_name: deploy-staging
      staging_namespace: staging
      enable_ephemeral: "false"
      needs: [build]

  - component: $CI_SERVER_FQDN/your-group/components/ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup
      job_name: cleanup

stages:
  - test
  - build
  - deploy-ephemeral
  - deploy-staging
  - deploy-production

deploy-production:
  stage: deploy-production
  image: bitnami/kubectl:latest
  rules:
    - if: '$CI_COMMIT_TAG'
      when: manual
  script:
    - kubectl set image deployment/app app=$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG -n production
    - kubectl rollout status deployment/app -n production
  environment:
    name: production
    url: https://production.example.com
```

### 3. Configure Kubernetes Namespaces

```bash
# Create namespaces
kubectl create namespace staging
kubectl create namespace production

# Create service account for GitLab (if not using GitLab Agent)
kubectl create serviceaccount gitlab-deploy -n staging
kubectl create serviceaccount gitlab-deploy -n production

# Grant permissions (example)
kubectl create rolebinding gitlab-deploy \
  --clusterrole=edit \
  --serviceaccount=staging:gitlab-deploy \
  -n staging
```

### 4. Configure GitLab Variables

In GitLab: **Settings → CI/CD → Variables**

```
KUBE_CONFIG          = <base64-encoded kubeconfig>
NPM_TOKEN            = <token-for-npm-packages> (optional)
DOCKER_AUTH_CONFIG   = <docker-registry-auth> (optional)
```

### 5. Create Kubernetes Deployment Manifest

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: ${IMAGE_TAG}  # Will be replaced by kubectl
        ports:
        - containerPort: 8080
        env:
        - name: ENVIRONMENT
          value: ${ENVIRONMENT}
---
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
```

---

## Troubleshooting

### Pipeline Fails on Test Stage

**Problem**: Tests fail with missing dependencies

**Solution**:

```yaml
# Add requirements_file input
- component: .../python-test@1.0.0
  inputs:
    requirements_file: requirements.txt  # Ensure file exists
```

### Container Build Fails

**Problem**: Dockerfile not found

**Solution**:

```yaml
# Specify Dockerfile path
- component: .../buildah-containerize@1.0.0
  inputs:
    dockerfile_path: Dockerfile  # Or custom path
```

### Deployment Fails: Namespace Not Found

**Problem**: Ephemeral namespace doesn't exist

**Solution**: The k8s-deploy component creates namespaces automatically. Ensure:

1. KUBECONFIG is set correctly
2. Service account has namespace creation permissions

### Cache Not Working

**Problem**: Dependencies re-install every time

**Solution**:

```yaml
# Ensure caching is enabled
- component: .../python-test@1.0.0
  inputs:
    enable_cache: "true"
    cache_key: "$CI_COMMIT_REF_SLUG"  # Default
```

### Production Deployment Stuck

**Problem**: Manual job not appearing

**Solution**:

1. Ensure you pushed a git tag: `git push origin v1.0.0`
2. Check rules in deploy-production job
3. Verify you have permission to run manual jobs

---

## Summary

| Phase | Trigger | Deploys To | Verification | Purpose |
| ----- | ------- | ---------- | ------------ | ------- |
| **Feature** | Push to branch | Ephemeral namespace | Smoke tests | Rapid iteration |
| **Staging** | Merge to main | Staging namespace | Integration tests | Pre-production testing |
| **Production** | Git tag | Production namespace | Production smoke tests | Live deployment |

**Key Benefits**:

- ⚡ Fast feedback with caching (30-70% faster)
- 🔒 Secure by default (TLS verification, no password leaks)
- 🔄 Easy rollback (redeploy previous tag)
- 🌐 Isolated testing (ephemeral namespaces)
- 📊 Full audit trail (GitLab history + tags)

**Next Steps**:

1. Review [examples/.gitlab-ci-complete-workflow.yml](examples/.gitlab-ci-complete-workflow.yml)
2. Customize for your language/framework
3. Test in a feature branch first
4. Roll out to your team!
