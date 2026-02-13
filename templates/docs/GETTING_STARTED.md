# Getting Started with GitLab CI/CD Components

This guide walks you through setting up and using GitLab CI/CD Components for the first time.

## Prerequisites

- GitLab instance (GitLab.com or Self-Managed 16.7+)
- A GitLab group where you can create projects
- Basic understanding of GitLab CI/CD
- Git installed locally

## Step-by-Step Setup

### Step 1: Create the Component Project

1. **Create a new GitLab project**

   ```bash
   # Navigate to your GitLab group
   # Click "New project" → "Create blank project"
   # Name: components
   # Visibility: Internal or Public (recommended for discoverability)
   ```

2. **Clone the repository locally**

   ```bash
   git clone git@gitlab.com:your-group/components.git
   cd components
   ```

3. **Copy the component files**

   ```bash
   # From your monorepo location
   cp -r /path/to/mono/components/* .
   ```

4. **Initialize the repository**

   ```bash
   git add .
   git commit -m "Initial component library setup"
   git push origin main
   ```

### Step 2: Enable CI/CD Catalog

1. **Navigate to your component project in GitLab**
2. Go to **Settings** → **General**
3. Expand **Visibility, project features, permissions**
4. Toggle **CI/CD Catalog project** to ON
5. Click **Save changes**

### Step 3: Create Your First Release

1. **Verify the `.gitlab-ci.yml` is present**

   ```bash
   cat .gitlab-ci.yml  # Should show the component test pipeline
   ```

2. **Create and push a semantic version tag**

   ```bash
   git tag -a 1.0.0 -m "Release 1.0.0: Initial component library"
   git push origin 1.0.0
   ```

3. **Monitor the release pipeline**
   - Go to **CI/CD** → **Pipelines** in GitLab
   - Watch the pipeline run (validate → test → release)
   - When complete, check **Deployments** → **Releases**
   - Verify release `1.0.0` was created

4. **Verify catalog listing**
   - Go to **Explore** → **CI/CD Catalog** (in GitLab top menu)
   - Search for your component project
   - You should see it listed with your components

### Step 4: Test Components in a Project

Now let's use the components in an actual project.

#### For a Python Project

1. **Navigate to your Python project**

   ```bash
   cd ../my-python-project
   ```

2. **Create/Update `.gitlab-ci.yml`**

   ```yaml
   # .gitlab-ci.yml
   include:
     - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
       inputs:
         stage: test
         job_name: test-app
         python_image: python:3.12
         requirements_file: requirements.txt
         test_command: pytest

     - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
       inputs:
         stage: build
         job_name: build-image
         needs: [test-app]

   stages:
     - test
     - build
   ```

   **Important**: Replace `your-group` with your actual GitLab group path!

3. **Commit and push**

   ```bash
   git add .gitlab-ci.yml
   git commit -m "Migrate to CI/CD components"
   git push
   ```

4. **Verify the pipeline**
   - Go to **CI/CD** → **Pipelines**
   - Click the latest pipeline
   - Verify both jobs run successfully:
     - `test-app` (from python-test component)
     - `build-image` (from buildah-containerize component)

#### For a Node.js Project

1. **Create `.gitlab-ci.yml`**

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

2. **Push and verify**

   ```bash
   git add .gitlab-ci.yml
   git commit -m "Add CI/CD pipeline using components"
   git push
   ```

#### For a Go Project

1. **Create `.gitlab-ci.yml`**

   ```yaml
   include:
     - component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
       inputs:
         stage: test
         go_image: golang:1.25

     - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
       inputs:
         stage: build

   stages: [test, build, deploy]
   ```

2. **Push and verify**

### Step 5: Advanced Usage - Full Pipeline

Create a complete pipeline with all stages:

```yaml
# .gitlab-ci.yml
include:
  # Test
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: test-application

  # Build
  - component: $CI_SERVER_FQDN/your-group/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      job_name: build-container
      needs: [test-application]

  # Promote (runs only when PROMOTE_TAG is set)
  - component: $CI_SERVER_FQDN/your-group/components/image-promote@1.0.0
    inputs:
      stage: promote
      job_name: promote-to-production
      target_tag: production

  # Deploy
  - component: $CI_SERVER_FQDN/your-group/components/k8s-deploy@1.0.0
    inputs:
      stage: deploy
      job_name: deploy-app
      staging_namespace: staging
      production_namespace: production

  # Cleanup (manual trigger)
  - component: $CI_SERVER_FQDN/your-group/components/ephemeral-cleanup@1.0.0
    inputs:
      stage: cleanup
      job_name: cleanup

stages:
  - test
  - build
  - promote
  - deploy
  - cleanup
```

### Step 6: Update Components

When you need to update a component:

1. **Make changes to the component**

   ```bash
   cd components
   # Edit templates/python-test.yml or other component
   git add .
   git commit -m "feat: add coverage report to python-test"
   git push
   ```

2. **Test the changes**
   - Pipeline runs automatically
   - Review test results

3. **Create a new release**

   ```bash
   # Minor version for new features
   git tag -a 1.1.0 -m "Release 1.1.0: Add coverage reports"
   git push origin 1.1.0

   # Or patch version for bug fixes
   # git tag -a 1.0.1 -m "Release 1.0.1: Fix python version detection"

   # Or major version for breaking changes
   # git tag -a 2.0.0 -m "Release 2.0.0: Restructured inputs"
   ```

4. **Update projects to use new version**

   ```yaml
   # Change from:
   - component: .../python-test@1.0.0

   # To:
   - component: .../python-test@1.1.0

   # Or use partial version to auto-update:
   - component: .../python-test@1.1  # Gets latest 1.1.x
   - component: .../python-test@1    # Gets latest 1.x.x
   ```

## Common Tasks

### View Available Components

1. Go to **Explore** → **CI/CD Catalog** in GitLab
2. Search for your component project
3. Click on it to see all available components
4. Click on a specific component to see:
   - Documentation
   - Available versions
   - Usage examples
   - Input parameters

### Debug Component Issues

1. **Check the pipeline output**
   - Look for error messages in failing jobs
   - Review which component was used

2. **Verify component version**

   ```yaml
   # Temporarily use a specific commit for debugging
   - component: $CI_SERVER_FQDN/group/components/my-component@$CI_COMMIT_SHA
   ```

3. **Review component source**
   - Navigate to the component project
   - Go to the `templates/` directory
   - Read the component's `template.yml`

### Rollback to Previous Version

If a new component version causes issues:

```yaml
# Simply change the version in your .gitlab-ci.yml
- component: .../python-test@1.0.0  # Rollback from 1.1.0 to 1.0.0
```

## Best Practices Checklist

- [ ] **Version pinning**: Use specific versions (`@1.0.0`) in production
- [ ] **Test before release**: Always test components before tagging
- [ ] **Semantic versioning**: Follow semver (MAJOR.MINOR.PATCH)
- [ ] **Documentation**: Keep README.md updated
- [ ] **Examples**: Provide usage examples
- [ ] **Security**: Review component code before using
- [ ] **Permissions**: Use minimal required permissions
- [ ] **Monitoring**: Watch for component usage across projects

## Troubleshooting

### Problem: Component not found

```text
Error: Component 'gitlab.com/group/components/my-component@1.0.0' - content not found
```

**Solution:**

1. Verify component project has "CI/CD Catalog project" enabled
2. Ensure at least one release is published
3. Check you have access to the component project (minimum Reporter role)

### Problem: Invalid version

```text
Error: Version '1.0.0' not found
```

**Solution:**

1. Check that release `1.0.0` exists in the component project
2. Go to **Deployments** → **Releases** to verify
3. Ensure the release was created successfully

### Problem: Missing inputs

```text
Error: Required input 'stage' not provided
```

**Solution:**

1. Check component's `spec:inputs:` section
2. Provide all required inputs in your `.gitlab-ci.yml`
3. Review component documentation

## Next Steps

1. **Explore examples**: Check `examples/` directory for more use cases
2. **Read migration guide**: See `MIGRATION.md` for detailed migration
3. **Customize components**: Add your own components to the library
4. **Share knowledge**: Teach your team about components
5. **Contribute**: Improve components and share back

## Resources

- **Quick Reference**: See `QUICKREF.md`
- **Architecture**: See `ARCHITECTURE.md`
- **Contributing**: See `CONTRIBUTING.md`
- **Examples**: See `examples/` directory
- **GitLab Docs**: <https://docs.gitlab.com/ci/components/>

---

**Need Help?** Create an issue in the component project or reach out to your GitLab admin!
