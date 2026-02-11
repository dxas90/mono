# Image Promote Component

Promotes container images by retagging them with new tags, useful for promoting staging images to production without rebuilding.

## Features

- 🏷️ **Image Retagging**: Promote existing images with new tags
- 🚀 **Fast Promotion**: No rebuild required, just pull-tag-push
- 🔒 **Secure**: Uses password-stdin for registry authentication
- 📦 **Artifact Export**: Exports promoted image tag for downstream jobs
- 🔧 **Configurable**: Custom source/target tags and registries
- ⚡ **Efficient**: Reuses existing image layers

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/image-promote@1.0.0
    inputs:
      stage: promote
      job_name: promote-to-production

variables:
  PROMOTE_TAG: "v1.0.0"

stages:
  - promote
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `promote` | No | Pipeline stage for the promote job |
| `job_name` | `promote-image` | No | Name of the promotion job |
| `source_tag` | `$IMAGE_TAG` | No | Source image tag to promote |
| `target_tag` | `$PROMOTE_TAG` | No | Target tag for promoted image |
| `image_repository` | `$CI_REGISTRY_IMAGE` | No | Container image repository |
| `registry` | `$CI_REGISTRY` | No | Container registry URL |
| `registry_user` | `$CI_REGISTRY_USER` | No | Registry username |
| `registry_password` | `$CI_REGISTRY_PASSWORD` | No | Registry password |
| `no_push` | `""` | No | Skip pushing to registry if set |
| `needs` | `[]` | No | Job dependencies |
| `rules` | `[{if: "$PROMOTE_TAG"}]` | No | Custom rules for when to run |

## Output Artifacts

| Artifact | Description |
| -------- | ----------- |
| `buildah-promotion.env` | Contains `PROMOTED_IMAGE` variable |

The `PROMOTED_IMAGE` can be used in downstream jobs.

## Use Cases

### 1. Promote Staging to Production

Promote a tested staging image to production without rebuilding:

```yaml
include:
  # Build and deploy to staging
  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build

  # Promote staging image to production tag
  - component: .../image-promote@1.0.0
    inputs:
      stage: promote
      job_name: promote-to-prod
      source_tag: "$CI_REGISTRY_IMAGE:latest"
      target_tag: "$CI_REGISTRY_IMAGE:v$CI_COMMIT_TAG"
    rules:
      - if: '$CI_COMMIT_TAG'
        when: manual

stages:
  - build
  - promote
```

### 2. Promote After Manual Approval

```yaml
- component: .../image-promote@1.0.0
  inputs:
    source_tag: "$CI_REGISTRY_IMAGE:staging"
    target_tag: "$CI_REGISTRY_IMAGE:production"
  rules:
    - if: '$CI_COMMIT_TAG'
      when: manual  # Require manual approval
```

### 3. Multi-Tag Promotion

Promote one image to multiple tags:

```yaml
- component: .../image-promote@1.0.0
  inputs:
    job_name: promote-latest
    source_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
    target_tag: "$CI_REGISTRY_IMAGE:latest"

- component: .../image-promote@1.0.0
  inputs:
    job_name: promote-version
    source_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
    target_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
```

## Complete Workflow Example

```yaml
include:
  # Test
  - component: .../python-test@1.0.0
    inputs:
      stage: test

  # Build container
  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [python-test]

  # Deploy to staging
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-staging
      staging_namespace: staging
      needs: [containerize]

  # Promote to production (manual, on tags)
  - component: .../image-promote@1.0.0
    inputs:
      stage: promote
      source_tag: "$CI_REGISTRY_IMAGE:latest"
      target_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
      needs: [deploy-staging]
    rules:
      - if: '$CI_COMMIT_TAG'
        when: manual

  # Deploy promoted image to production
  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-production
      production_namespace: production
      needs: [promote-image]
    rules:
      - if: '$CI_COMMIT_TAG'

stages:
  - test
  - build
  - deploy-staging
  - promote
  - deploy-production
```

## Advanced Examples

### Promote from External Registry

```yaml
- component: .../image-promote@1.0.0
  inputs:
    source_tag: "docker.io/myapp:staging"
    target_tag: "$CI_REGISTRY_IMAGE:production"
    registry: "$CI_REGISTRY"
```

### Test Promotion (No Push)

```yaml
- component: .../image-promote@1.0.0
  inputs:
    source_tag: "$CI_REGISTRY_IMAGE:staging"
    target_tag: "$CI_REGISTRY_IMAGE:test-promotion"
    no_push: "true"  # Don't push, just test
```

### Conditional Promotion

```yaml
- component: .../image-promote@1.0.0
  inputs:
    source_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
    target_tag: "$CI_REGISTRY_IMAGE:production"
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v[0-9]+\.[0-9]+\.[0-9]+$/'  # Semantic versioning only
      when: manual
```

### With Custom Variables

Set `PROMOTE_TAG` via GitLab UI or API:

```yaml
- component: .../image-promote@1.0.0
  inputs:
    target_tag: "$CI_REGISTRY_IMAGE:$PROMOTE_TAG"
  rules:
    - if: '$PROMOTE_TAG'
```

Then trigger manually:

```bash
# Via API
curl -X POST "https://gitlab.com/api/v4/projects/$PROJECT_ID/pipeline" \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --form "ref=main" \
  --form "variables[PROMOTE_TAG]=v1.2.3"
```

## Benefits Over Rebuilding

1. **Speed**: No build time, just pull-tag-push (seconds vs minutes)
2. **Consistency**: Exact same image that was tested in staging
3. **Reliability**: No build environment differences
4. **Traceability**: Clear lineage from staging to production
5. **Storage**: Reuses layers, saves registry space

## Troubleshooting

### Source Image Not Found

**Problem**: `Error: image not known`

**Solution**: Ensure source image exists and tag is correct:

```bash
# Check local GitLab registry
curl -H "PRIVATE-TOKEN: $TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/registry/repositories"
```

### Target Tag Not Set

**Problem**: `ERROR: TARGET_TAG (promotion tag) is not set`

**Solution**: Set `PROMOTE_TAG` variable or specify `target_tag`:

```yaml
variables:
  PROMOTE_TAG: "v1.0.0"

# or

inputs:
  target_tag: "$CI_REGISTRY_IMAGE:production"
```

### Authentication Failed

**Problem**: `Error: authentication required`

**Solution**: Ensure registry credentials are correct:

```yaml
# For GitLab Container Registry, use default variables
registry: "$CI_REGISTRY"
registry_user: "$CI_REGISTRY_USER"
registry_password: "$CI_REGISTRY_PASSWORD"
```

### Permission Denied

**Problem**: `Error: unauthorized: access forbidden`

**Solution**: Ensure service account has push permissions to registry.

### Wrong Image Promoted

**Problem**: Promoted wrong image

**Solution**: Verify source tag:

```yaml
before_script:
  - echo "Promoting $SOURCE_TAG to $TARGET_TAG"
  - buildah images  # List available images
```

## Best Practices

1. **Manual Approval for Production**: Require manual approval

   ```yaml
   rules:
     - if: '$CI_COMMIT_TAG'
       when: manual
   ```

2. **Semantic Versioning**: Use proper version tags

   ```yaml
   target_tag: "$CI_REGISTRY_IMAGE:v$CI_COMMIT_TAG"
   ```

3. **Verify Before Promoting**: Run tests on staging first

   ```yaml
   needs:
     - job: test-staging
       optional: false
   ```

4. **Tag Multiple Targets**: Promote to `latest` and version tag

   ```yaml
   # Promote to version tag
   - component: .../image-promote@1.0.0
     inputs:
       target_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"

   # Also update latest
   - component: .../image-promote@1.0.0
     inputs:
       target_tag: "$CI_REGISTRY_IMAGE:latest"
   ```

5. **Document Promotions**: Add comments or labels

   ```bash
   buildah tag --annotation "promoted-from=staging" \
     "$SOURCE_TAG" "$TARGET_TAG"
   ```

## Integration with Other Components

### Complete Production Pipeline

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
      stage: deploy-staging
      staging_namespace: staging
      needs: [containerize]

  - component: .../image-promote@1.0.0
    inputs:
      stage: promote
      source_tag: "$CI_REGISTRY_IMAGE:latest"
      target_tag: "$CI_REGISTRY_IMAGE:$CI_COMMIT_TAG"
      needs: [deploy-staging]
    rules:
      - if: '$CI_COMMIT_TAG'
        when: manual

  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy-production
      production_namespace: production
      needs: [promote-image]
    rules:
      - if: '$CI_COMMIT_TAG'

stages:
  - test
  - build
  - deploy-staging
  - promote
  - deploy-production
```

## Version History

- **1.0.0**: Initial release
  - Image pull-tag-push workflow
  - Secure password handling
  - Artifact export
  - Validation and error handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
