# Kubernetes Deploy Component

Deploys applications to Kubernetes with automatic namespace management for Feature → Staging → Production workflow.

## Features

- 🚀 **Automatic Deployment**: Smart routing to ephemeral, staging, or production namespaces
- 🌿 **Ephemeral Environments**: Feature branches deploy to isolated namespaces
- 🔄 **Workflow Support**: Feature → Staging → Production deployment flow
- 📝 **Manifest Support**: Standard Kubernetes YAML manifests
- 🔧 **Configurable**: Custom namespaces, manifests, and kubectl images
- 🏗️ **Namespace Management**: Automatic namespace creation
- 🔗 **Build Integration**: Sources image tags from build artifacts

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy
      job_name: deploy

stages:
  - deploy
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `deploy` | No | Pipeline stage for the deploy job |
| `job_name` | `deploy` | No | Name of the deployment job |
| `kubectl_image` | `bitnami/kubectl:latest` | No | kubectl container image |
| `k8s_manifest_path` | `k8s/deployment.yaml` | No | Path to Kubernetes manifest file |
| `ephemeral_namespace` | `$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG` | No | Namespace for feature branch deployments |
| `staging_namespace` | `staging` | No | Namespace for staging (main branch) |
| `production_namespace` | `production` | No | Namespace for production (git tags) |
| `enable_ephemeral` | `true` | No | Enable ephemeral deployments for feature branches |
| `needs` | `[]` | No | Job dependencies |

## Deployment Flow

The component automatically determines the target namespace based on Git context:

| Git Context | Target Namespace | Example |
| ----------- | ---------------- | ------- |
| Feature branch | `$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG` | `myapp-feature-auth` |
| Main branch | `staging` | `staging` |
| Git tag | `production` | `production` |

## Complete Example

```yaml
include:
  # Build container
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build

  # Deploy to appropriate namespace
  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy
      job_name: deploy
      k8s_manifest_path: k8s/deployment.yaml
      ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"
      staging_namespace: staging
      production_namespace: production
      needs: [build]

stages:
  - build
  - deploy
```

## Kubernetes Manifest

Create a `k8s/deployment.yaml` file in your repository:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
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
          image: ${CI_REGISTRY_IMAGE}:${CI_COMMIT_REF_SLUG}
          ports:
            - containerPort: 8080
          env:
            - name: ENVIRONMENT
              value: "${CI_ENVIRONMENT_NAME}"
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
  type: LoadBalancer
```

## Advanced Examples

### Disable Ephemeral Deployments

Only deploy to staging and production:

```yaml
- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    enable_ephemeral: "false"
    staging_namespace: staging
    production_namespace: production
```

### Custom Namespace Names

```yaml
- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    ephemeral_namespace: "preview-$CI_COMMIT_REF_SLUG"
    staging_namespace: "uat"
    production_namespace: "prod"
```

### Multiple Manifest Files

```yaml
- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    k8s_manifest_path: k8s/  # Deploy all files in directory
```

### With Image Tag from Build

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
      needs:
        - job: build
          artifacts: true  # Get IMAGE_TAG from build.env
```

The `build.env` artifact provides `$IMAGE_TAG` variable for use in manifests.

### Custom kubectl Image

```yaml
- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    kubectl_image: alpine/k8s:1.28.0
```

### Monorepo Multiple Services

```yaml
- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    job_name: deploy-api
    k8s_manifest_path: apps/api/k8s/deployment.yaml
    needs: [build-api]

- component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
  inputs:
    job_name: deploy-frontend
    k8s_manifest_path: apps/frontend/k8s/deployment.yaml
    needs: [build-frontend]
```

### With Environment URLs

```yaml
deploy:
  extends: .k8s-deploy
  environment:
    name: production
    url: https://production.example.com
  rules:
    - if: '$CI_COMMIT_TAG'
```

### With Manual Approval (Production)

```yaml
deploy-staging:
  stage: deploy
  # ... auto-deploy to staging

deploy-production:
  stage: deploy
  when: manual  # Require manual approval
  rules:
    - if: '$CI_COMMIT_TAG'
```

## Workflow Examples

### Feature → Staging → Production

```yaml
include:
  - component: .../python-test@1.0.0
    inputs:
      stage: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [python-test]

  # Feature branches → ephemeral namespace
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-ephemeral
      job_name: deploy-feature
      enable_ephemeral: "true"
      needs: [containerize]

  # Main branch → staging namespace
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-staging
      job_name: deploy-staging
      staging_namespace: staging
      enable_ephemeral: "false"
      needs: [containerize]
    rules:
      - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

  # Tags → production namespace (manual)
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-production
      job_name: deploy-production
      production_namespace: production
      enable_ephemeral: "false"
      needs: [containerize]
    rules:
      - if: '$CI_COMMIT_TAG'
        when: manual

stages:
  - test
  - build
  - deploy-ephemeral
  - deploy-staging
  - deploy-production
```

## Setup Requirements

### 1. Kubernetes Cluster Access

Configure access to your Kubernetes cluster by adding `KUBECONFIG` variable:

**GitLab Settings → CI/CD → Variables**:

```
KUBE_CONFIG = <base64-encoded kubeconfig file>
```

To encode your kubeconfig:

```bash
cat ~/.kube/config | base64 -w 0
```

### 2. Create Namespaces

Create the staging and production namespaces:

```bash
kubectl create namespace staging
kubectl create namespace production
```

Ephemeral namespaces are created automatically.

### 3. Service Account Permissions

Ensure the service account has permissions to:

- Create namespaces
- Deploy resources (deployments, services, etc.)
- Update existing resources

Example RBAC:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gitlab-deploy
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["create", "get", "list"]
  - apiGroups: ["apps", ""]
    resources: ["deployments", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
```

## Troubleshooting

### Deployment Fails: Namespace Not Found

**Problem**: `Error from server (NotFound): namespaces "staging" not found`

**Solution**: Create the namespace manually:

```bash
kubectl create namespace staging
kubectl create namespace production
```

Ephemeral namespaces are created automatically by the component.

### Deployment Fails: Forbidden

**Problem**: `Error from server (Forbidden): ... is forbidden`

**Solution**: Ensure the service account has appropriate permissions:

```bash
kubectl create clusterrolebinding gitlab-deploy \
  --clusterrole=cluster-admin \
  --serviceaccount=default:gitlab-deploy
```

### KUBECONFIG Not Found

**Problem**: `The connection to the server localhost:8080 was refused`

**Solution**: Ensure `KUBE_CONFIG` variable is set in GitLab CI/CD settings.

### Image Pull Errors

**Problem**: `ErrImagePull` or `ImagePullBackOff`

**Solution**: Create image pull secret:

```bash
kubectl create secret docker-registry gitlab-registry \
  --docker-server=$CI_REGISTRY \
  --docker-username=$CI_DEPLOY_USER \
  --docker-password=$CI_DEPLOY_PASSWORD \
  -n staging
```

Add to your deployment:

```yaml
spec:
  imagePullSecrets:
    - name: gitlab-registry
```

### Ephemeral Namespace Not Created

**Problem**: Feature branch doesn't deploy

**Solution**: Check that:

1. `enable_ephemeral: "true"` (default)
2. Not on main branch
3. Not a tag
4. Service account has namespace creation permissions

### Wrong Namespace

**Problem**: Deploys to wrong namespace

**Solution**: Verify Git context and namespace configuration:

```yaml
- component: .../k8s-deploy@1.0.0
  inputs:
    ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"
    staging_namespace: "staging"
    production_namespace: "production"
```

## Best Practices

1. **Use Namespace Isolation**: Separate ephemeral, staging, and production

   ```yaml
   ephemeral_namespace: "preview-$CI_COMMIT_REF_SLUG"
   staging_namespace: "staging"
   production_namespace: "production"
   ```

2. **Manual Production Approval**: Require manual approval for production

   ```yaml
   rules:
     - if: '$CI_COMMIT_TAG'
       when: manual
   ```

3. **Resource Limits**: Set resource limits in manifests

   ```yaml
   resources:
     requests:
       memory: "128Mi"
       cpu: "100m"
     limits:
       memory: "512Mi"
       cpu: "500m"
   ```

4. **Health Checks**: Configure liveness and readiness probes

   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 8080
   readinessProbe:
     httpGet:
       path: /ready
       port: 8080
   ```

5. **Environment Variables**: Use ConfigMaps and Secrets

   ```yaml
   envFrom:
     - configMapRef:
         name: app-config
     - secretRef:
         name: app-secrets
   ```

6. **Cleanup Old Deployments**: Use ephemeral-cleanup component

   ```yaml
   - component: .../ephemeral-cleanup@1.0.0
     inputs:
       stage: cleanup
   ```

## Integration with Other Components

### Complete CI/CD Pipeline

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

  - component: .../ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup

stages:
  - test
  - build
  - deploy
  - cleanup
```

## Version History

- **1.0.0**: Initial release
  - Automatic namespace routing
  - Ephemeral environment support
  - Staging and production deployments
  - Manifest-based deployment
  - Build artifact integration

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
