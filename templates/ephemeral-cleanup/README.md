# Ephemeral Cleanup Component

Cleans up ephemeral Kubernetes namespaces created during feature branch development, freeing cluster resources.

## Features

- 🧹 **Resource Cleanup**: Deletes ephemeral namespaces and all contained resources
- 🔒 **Safe Defaults**: Manual trigger to prevent accidental deletion
- 🎯 **Branch-Specific**: Targets feature branch namespaces only
- ⚙️ **Configurable**: Custom namespace patterns and kubectl images
- ✅ **Fault Tolerant**: Continues even if namespace doesn't exist
- 📋 **MR Integration**: Automatically available on feature branch pipelines

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup
      job_name: cleanup-feature-env

stages:
  - cleanup
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `cleanup` | No | Pipeline stage for the cleanup job |
| `job_name` | `cleanup-ephemeral` | No | Name of the cleanup job |
| `kubectl_image` | `bitnami/kubectl:latest` | No | kubectl container image |
| `ephemeral_namespace` | `$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG` | No | Namespace to clean up |
| `needs` | `[]` | No | Job dependencies |

## When It Runs

The component runs **manually** on:

- **Feature branch pushes**: Clean up after testing
- **Merge request pipelines**: Clean up preview environments

The job **does not run** on:

- Main/default branch
- Git tags
- Production deployments

This prevents accidental deletion of staging or production namespaces.

## Complete Example

```yaml
include:
  # Deploy to ephemeral namespace
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy
      ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"

  # Cleanup job (manual)
  - component: .../ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup
      ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"

stages:
  - deploy
  - cleanup
```

## Usage Workflow

### 1. Feature Branch Development

```
Developer → Push to feature branch
           ↓
        Pipeline runs → Creates ephemeral namespace
           ↓
        Developer tests in ephemeral environment
           ↓
        Developer manually triggers cleanup job
           ↓
        Ephemeral namespace deleted
```

### 2. Merge Request Flow

```
Developer → Create MR
           ↓
        MR pipeline runs → Creates ephemeral namespace
           ↓
        Review happens in ephemeral environment
           ↓
        MR merged → Manually trigger cleanup
           ↓
        Ephemeral namespace deleted
```

## Advanced Examples

### Custom Namespace Pattern

```yaml
- component: .../ephemeral-cleanup@1.0.0
  inputs:
    ephemeral_namespace: "preview-$CI_COMMIT_REF_SLUG"
```

### Auto-Cleanup on MR Close

```yaml
- component: .../ephemeral-cleanup@1.0.0
  rules:
    - if: '$CI_MERGE_REQUEST_EVENT_TYPE == "close"'
      when: always  # Auto-cleanup when MR closes
```

### Cleanup After Successful Deploy

```yaml
- component: .../ephemeral-cleanup@1.0.0
  inputs:
    needs: [deploy-to-staging]
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      when: manual
```

### Multiple Namespaces

Clean up multiple related namespaces:

```yaml
- component: .../ephemeral-cleanup@1.0.0
  inputs:
    job_name: cleanup-api
    ephemeral_namespace: "$CI_PROJECT_NAME-api-$CI_COMMIT_REF_SLUG"

- component: .../ephemeral-cleanup@1.0.0
  inputs:
    job_name: cleanup-frontend
    ephemeral_namespace: "$CI_PROJECT_NAME-frontend-$CI_COMMIT_REF_SLUG"
```

### Custom kubectl Image

```yaml
- component: .../ephemeral-cleanup@1.0.0
  inputs:
    kubectl_image: alpine/k8s:1.28.0
```

### Auto-Cleanup Old Namespaces

Clean up namespaces older than 7 days:

```yaml
cleanup-old-namespaces:
  stage: cleanup
  image: bitnami/kubectl:latest
  script:
    - |
      kubectl get namespaces -o json | \
      jq -r '.items[] | select(.metadata.name | startswith("'$CI_PROJECT_NAME'-")) |
        select((now - (.metadata.creationTimestamp | fromdateiso8601)) > (7*86400)) |
        .metadata.name' | \
      xargs -I {} kubectl delete namespace {}
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
```

## What Gets Deleted

When the cleanup job runs, it deletes:

- The entire Kubernetes namespace
- All resources within that namespace:
  - Deployments
  - Services
  - Pods
  - ConfigMaps
  - Secrets
  - Ingresses
  - PersistentVolumeClaims (if namespace-scoped)
  - Any other namespace-scoped resources

**Note**: Cluster-scoped resources (ClusterRoles, PersistentVolumes, etc.) are NOT deleted.

## Safety Features

### 1. Manual Trigger

By default, cleanup is **manual** to prevent accidental deletion:

```yaml
rules:
  - when: manual
```

### 2. Allow Failure

Job can fail without blocking pipeline:

```yaml
allow_failure: true
```

### 3. Namespace Pattern Check

Only runs on feature branches, not main/production:

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH && $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH'
```

### 4. Idempotent

Safe to run multiple times - continues if namespace doesn't exist:

```bash
kubectl delete namespace $NAMESPACE || echo 'Namespace already removed'
```

## Troubleshooting

### Cleanup Job Not Appearing

**Problem**: Cleanup job doesn't show in pipeline

**Solution**: Ensure you're on a feature branch, not main:

```yaml
# Check current branch
echo $CI_COMMIT_BRANCH
echo $CI_DEFAULT_BRANCH
```

### Permission Denied

**Problem**: `Error: Forbidden: User cannot delete namespace`

**Solution**: Grant delete permissions to service account:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gitlab-cleanup
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["delete"]
```

```bash
kubectl create clusterrolebinding gitlab-cleanup \
  --clusterrole=gitlab-cleanup \
  --serviceaccount=default:gitlab-deploy
```

### Namespace Stuck in Terminating

**Problem**: Namespace stuck in `Terminating` state

**Solution**: Force delete finalizers:

```bash
kubectl get namespace $NAMESPACE -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f -
```

Or check for resources blocking deletion:

```bash
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n $NAMESPACE
```

### Wrong Namespace Deleted

**Problem**: Deleted wrong namespace

**Solution**: Verify namespace before deletion:

```yaml
script:
  - echo "About to delete: $EPHEMERAL_NAMESPACE"
  - kubectl get namespace $EPHEMERAL_NAMESPACE  # Verify it exists
  - sleep 5  # Give time to cancel if wrong
  - kubectl delete namespace $EPHEMERAL_NAMESPACE
```

## Best Practices

1. **Use Manual Trigger**: Prevent accidental deletion

   ```yaml
   rules:
     - when: manual
   ```

2. **Verify Namespace Pattern**: Ensure correct namespace

   ```yaml
   ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"
   ```

3. **Schedule Cleanup**: Auto-clean old namespaces

   ```yaml
   rules:
     - if: '$CI_PIPELINE_SOURCE == "schedule"'
   ```

4. **Notify Team**: Send notification before cleanup

   ```yaml
   before_script:
     - echo "Cleaning up $EPHEMERAL_NAMESPACE - notifying team"
     - curl -X POST $SLACK_WEBHOOK -d "Cleaning up $EPHEMERAL_NAMESPACE"
   ```

5. **Backup Important Data**: Export data before cleanup

   ```yaml
   before_script:
     - kubectl get all -n $EPHEMERAL_NAMESPACE -o yaml > backup.yaml
   ```

6. **Document Cleanup**: Add job description

   ```yaml
   "$[[ inputs.job_name ]]":
     description: "Manually clean up ephemeral namespace $EPHEMERAL_NAMESPACE"
   ```

## Integration with Other Components

### Complete Feature Branch Workflow

```yaml
include:
  # Test
  - component: .../python-test@1.0.0
    inputs:
      stage: test

  # Build
  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [python-test]

  # Deploy to ephemeral
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy
      ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"
      needs: [containerize]

  # Cleanup (manual)
  - component: .../ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup
      ephemeral_namespace: "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"

stages:
  - test
  - build
  - deploy
  - cleanup
```

### With Scheduled Cleanup

```yaml
include:
  - component: .../ephemeral-cleanup@1.0.0

variables:
  MAX_AGE_DAYS: 7

cleanup-old-environments:
  extends: .ephemeral-cleanup
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: always
```

## Automated Cleanup Strategies

### 1. On Branch Delete

Cleanup when GitExt branch is deleted:

```yaml
cleanup-on-delete:
  stage: cleanup
  image: bitnami/kubectl:latest
  script:
    - kubectl delete namespace "$CI_PROJECT_NAME-$CI_COMMIT_REF_SLUG"
  rules:
    - if: '$CI_COMMIT_BEFORE_SHA == "0000000000000000000000000000000000000000"'
```

### 2. Age-Based Cleanup

Schedule job to clean old namespaces:

```yaml
cleanup-old:
  stage: cleanup
  image: bitnami/kubectl:latest
  script:
    - |
      # Delete namespaces older than 7 days
      kubectl get ns -l managed-by=gitlab-ci -o json | \
      jq -r ".items[] | select((now - (.metadata.creationTimestamp | fromdateiso8601)) > 604800) | .metadata.name" | \
      xargs -r kubectl delete namespace
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
  allow_failure: true
```

### 3. Resource-Based Cleanup

Cleanup when resource usage is low:

```yaml
cleanup-unused:
  stage: cleanup
  script:
    - |
      # Check if namespace has active pods
      POD_COUNT=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
      if [ "$POD_COUNT" -eq "0" ]; then
        kubectl delete namespace $NAMESPACE
      fi
```

## Version History

- **1.0.0**: Initial release
  - Manual namespace deletion
  - Feature branch safety
  - Fault-tolerant deletion
  - MR pipeline integration

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
