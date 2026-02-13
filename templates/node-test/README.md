# Node.js Test Component

Executes Node.js tests with Jest/Vitest/Mocha, supports caching, coverage reporting, and test result artifacts.

## Features

- ✅ **Test Framework Support**: Works with Jest, Vitest, Mocha, Ava, and others
- ⚡ **Dependency Caching**: 40-60% faster builds with pnpm cache
- 📊 **Test Reports**: JUnit XML reports integrated with GitLab UI
- 📈 **Coverage Reports**: Cobertura XML coverage with GitLab visualization
- 🔧 **Configurable**: All major options exposed as inputs
- 📦 **Package Manager Support**: pnpm, npm, yarn, bun
- 🏗️ **Build Step Included**: Optional build before testing

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
    inputs:
      stage: test
      job_name: test-nodejs-app

stages:
  - test
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `test` | No | Pipeline stage for the test job |
| `job_name` | `node-test` | No | Name of the test job |
| `node_image` | `node:22-alpine` | No | Node.js Docker image |
| `pnpm_version` | `10.18.1` | No | pnpm version to use |
| `install_command` | `pnpm install --frozen-lockfile` | No | Package installation command |
| `build_command` | `pnpm build` | No | Build command (optional) |
| `test_command` | `pnpm test` | No | Test command to run |
| `allow_test_failure` | `false` | No | Continue pipeline even if tests fail |
| `enable_cache` | `true` | No | Enable dependency caching |
| `cache_key` | `$CI_COMMIT_REF_SLUG` | No | Cache key for dependencies |
| `cache_paths` | `["node_modules/", ".pnpm-store/"]` | No | Paths to cache |
| `cache_policy` | `pull-push` | No | Cache policy (pull-push, pull, push) |
| `enable_test_report` | `false` | No | Enable JUnit test report generation |
| `test_report_path` | `junit.xml` | No | Path to JUnit XML test report |
| `enable_coverage` | `false` | No | Enable coverage report generation |
| `coverage_path` | `coverage/cobertura-coverage.xml` | No | Path to coverage report |
| `coverage_format` | `cobertura` | No | Coverage report format |
| `needs` | `[]` | No | Job dependencies |

## Output Artifacts

| Artifact | Condition | Description |
| -------- | --------- | ----------- |
| JUnit XML | `enable_test_report=true` | Test results shown in GitLab MR |
| Coverage XML | `enable_coverage=true` | Coverage shown in GitLab MR diff |
| HTML Coverage | `enable_coverage=true` | Browse-able coverage report |

## Complete Example with Coverage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
    inputs:
      stage: test
      job_name: test-with-coverage
      node_image: node:22-alpine
      pnpm_version: "10.18.1"
      install_command: pnpm install --frozen-lockfile
      build_command: pnpm build
      test_command: pnpm test -- --coverage --coverageReporters=cobertura --coverageReporters=html
      enable_cache: "true"
      enable_test_report: "true"
      test_report_path: junit.xml
      enable_coverage: "true"
      coverage_path: coverage/cobertura-coverage.xml

stages:
  - test
```

### Setup for Coverage (Jest)

Add to your `package.json`:

```json
{
  "devDependencies": {
    "jest": "^29.0.0",
    "jest-junit": "^16.0.0"
  },
  "jest": {
    "reporters": [
      "default",
      ["jest-junit", {
        "outputDirectory": ".",
        "outputName": "junit.xml"
      }]
    ],
    "coverageReporters": ["text", "cobertura", "html"]
  },
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage"
  }
}
```

Run locally:

```bash
pnpm test -- --coverage --coverageReporters=cobertura --coverageReporters=html
```

### GitLab Integration

With `enable_test_report` and `enable_coverage` enabled:

1. **Test Results in MR**:
   - Shows test pass/fail summary
   - Links to failed tests
   - Historical test trend

2. **Coverage in MR Diff**:
   - Shows coverage % for changed lines
   - Highlights uncovered code
   - Tracks coverage trends

## Advanced Examples

### Using npm Instead of pnpm

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    node_image: node:22-alpine
    install_command: npm ci
    build_command: npm run build
    test_command: npm test
    cache_paths: ["node_modules/"]
```

### Using Yarn

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    node_image: node:22-alpine
    install_command: yarn install --frozen-lockfile
    build_command: yarn build
    test_command: yarn test
    cache_paths: ["node_modules/", ".yarn/"]
```

### Using Bun

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    node_image: oven/bun:1
    install_command: bun install --frozen-lockfile
    build_command: bun run build
    test_command: bun test
    cache_paths: ["node_modules/"]
```

### Monorepo Workspace Testing

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    job_name: test-api
    install_command: pnpm install --frozen-lockfile
    test_command: pnpm --filter @myapp/api test
    cache_key: "api-$CI_COMMIT_REF_SLUG"

- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    job_name: test-frontend
    install_command: pnpm install --frozen-lockfile
    test_command: pnpm --filter @myapp/frontend test
    cache_key: "frontend-$CI_COMMIT_REF_SLUG"
```

### With Vitest

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    test_command: pnpm vitest run --coverage --reporter=junit --reporter=default
    enable_test_report: "true"
    test_report_path: junit.xml
    enable_coverage: "true"
```

### With Playwright E2E Tests

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    job_name: e2e-tests
    node_image: mcr.microsoft.com/playwright:v1.40.0
    test_command: pnpm playwright test --reporter=junit
    enable_test_report: "true"
    test_report_path: test-results/junit.xml
```

### Different Node Version

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    node_image: node:20-alpine
```

### Skip Build Step

```yaml
- component: $CI_SERVER_FQDN/your-group/components/node-test@1.0.0
  inputs:
    build_command: "echo 'Skipping build'"
    test_command: pnpm test
```

## Performance Tips

### Caching (Enabled by Default)

The component caches:

- `node_modules/` - Installed dependencies
- `.pnpm-store/` - pnpm store directory

This provides **40-60% faster** subsequent builds.

### Disable Caching (Not Recommended)

```yaml
- component: .../node-test@1.0.0
  inputs:
    enable_cache: "false"
```

### Custom Cache Key

```yaml
- component: .../node-test@1.0.0
  inputs:
    cache_key: "node-$CI_COMMIT_REF_SLUG-$CI_PROJECT_ID"
```

### Cache Pull-Only on Feature Branches

```yaml
- component: .../node-test@1.0.0
  inputs:
    cache_policy: "pull"  # Don't update cache on feature branches
```

## Troubleshooting

### Tests Not Failing Pipeline

**Problem**: Tests fail but pipeline passes

**Solution**: Ensure `allow_test_failure` is `false` (default):

```yaml
- component: .../node-test@1.0.0
  inputs:
    allow_test_failure: "false"  # Default, fails pipeline on test failure
```

### Missing Dependencies

**Problem**: Module not found errors

**Solution**: Verify lock file exists and installation command is correct:

```yaml
- component: .../node-test@1.0.0
  inputs:
    install_command: pnpm install --frozen-lockfile  # or npm ci / yarn install --frozen-lockfile
```

### Coverage Not Showing in GitLab

**Problem**: Coverage report not visible in MR

**Solution**: Ensure all three conditions met:

1. `enable_coverage: "true"`
2. `coverage_path` points to Cobertura XML file
3. Test command generates coverage in Cobertura format:

   ```shell
   pnpm test -- --coverage --coverageReporters=cobertura
   ```

### Cache Not Working

**Problem**: Dependencies re-install every time

**Solution**: Check that:

1. `enable_cache: "true"` (default)
2. Runner has distributed cache configured
3. Same `cache_key` between runs (default uses branch name)
4. Verify `cache_paths` match your package manager

### Build Fails on Alpine

**Problem**: `Error: Cannot find module 'node:crypto'` or similar

**Solution**: Use full Node image instead of Alpine:

```yaml
- component: .../node-test@1.0.0
  inputs:
    node_image: node:22  # Full image, not Alpine
```

### pnpm Version Mismatch

**Problem**: `ERR_PNPM_UNSUPPORTED_ENGINE`

**Solution**: Specify correct pnpm version:

```yaml
- component: .../node-test@1.0.0
  inputs:
    pnpm_version: "9.0.0"  # Match your package.json packageManager field
```

## Best Practices

1. **Always Enable Coverage**: Track code coverage trends

   ```yaml
   enable_coverage: "true"
   ```

2. **Enable Test Reports**: See test results in GitLab MR

   ```yaml
   enable_test_report: "true"
   ```

3. **Use Caching**: Speeds up builds significantly

   ```yaml
   enable_cache: "true"  # Default
   ```

4. **Fail Fast**: Don't suppress test failures

   ```yaml
   allow_test_failure: "false"  # Default
   ```

5. **Lock Dependencies**: Use frozen lock files

   ```yaml
   install_command: "pnpm install --frozen-lockfile"
   ```

6. **Use Specific Node Versions**: Pin to exact versions

   ```yaml
   node_image: "node:22.1.0-alpine"
   ```

## Integration with Other Components

### With Buildah Containerize

```yaml
include:
  - component: .../node-test@1.0.0
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
  - component: .../node-test@1.0.0
    inputs:
      stage: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [node-test]

  - component: .../k8s-deploy@1.0.0
    inputs:
      stage: deploy
      needs: [containerize]

stages:
  - test
  - build
  - deploy
```

## Version History

- **1.0.0**: Initial release
  - Jest/Vitest/Mocha support
  - Dependency caching (pnpm, npm, yarn)
  - Test reports
  - Coverage reports
  - Configurable failure handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
