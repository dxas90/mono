# Go Test Component

Executes Go tests with coverage support, race detection, and test result artifacts.

## Features

- ✅ **Go Testing**: Native `go test` integration with all features
- 🏁 **Race Detection**: Optional race condition detection
- ⚡ **Dependency Caching**: 40-60% faster builds with module cache
- 📊 **Test Reports**: JUnit XML reports integrated with GitLab UI
- 📈 **Coverage Reports**: Cobertura XML coverage with GitLab visualization
- 🔧 **Configurable**: Build flags, test flags, and coverage options
- 🚀 **Fast Execution**: Parallel test execution support

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
    inputs:
      stage: test
      job_name: test-go-app

stages:
  - test
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `test` | No | Pipeline stage for the test job |
| `job_name` | `go-test` | No | Name of the test job |
| `go_image` | `golang:1.25` | No | Go Docker image |
| `build_flags` | `-v` | No | Go build flags |
| `test_flags` | `-v` | No | Go test flags |
| `allow_test_failure` | `false` | No | Continue pipeline even if tests fail |
| `enable_cache` | `true` | No | Enable dependency caching |
| `cache_key` | `$CI_COMMIT_REF_SLUG` | No | Cache key for dependencies |
| `cache_paths` | `[".go-pkg/", "~/go/pkg/mod/"]` | No | Paths to cache |
| `cache_policy` | `pull-push` | No | Cache policy (pull-push, pull, push) |
| `enable_test_report` | `false` | No | Enable JUnit test report (requires gotestsum) |
| `test_report_path` | `test-report.xml` | No | Path to JUnit XML test report |
| `enable_coverage` | `false` | No | Enable coverage report generation |
| `coverage_path` | `coverage.xml` | No | Path to coverage report (Cobertura XML) |
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
  - component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
    inputs:
      stage: test
      job_name: test-with-coverage
      go_image: golang:1.25
      build_flags: -v
      test_flags: -v -race -coverprofile=coverage.out -covermode=atomic
      enable_cache: "true"
      enable_test_report: "true"
      test_report_path: test-report.xml
      enable_coverage: "true"
      coverage_path: coverage.xml

stages:
  - test
```

### Setup for Coverage

Install required tools:

```bash
# For JUnit XML reports
go install gotest.tools/gotestsum@latest

# For Cobertura coverage format
go install github.com/boumenot/gocover-cobertura@latest
```

Run locally:

```bash
# Run tests with coverage
go test -v -race -coverprofile=coverage.out -covermode=atomic ./...

# Generate JUnit XML
gotestsum --junitfile test-report.xml --format testname

# Convert coverage to Cobertura XML
gocover-cobertura < coverage.out > coverage.xml

# Generate HTML coverage
go tool cover -html=coverage.out -o coverage.html
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

### With Race Detection

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    test_flags: -v -race -coverprofile=coverage.out
```

### Different Go Version

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    go_image: golang:1.22
```

### With Build Tags

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    build_flags: -v -tags=integration
    test_flags: -v -tags=integration
```

### Short Test Mode

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    test_flags: -v -short  # Skip long-running tests
```

### Parallel Test Execution

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    test_flags: -v -race -parallel=4
```

### With Specific Package

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    test_flags: -v ./pkg/...  # Test only pkg directory
```

### CGO Disabled

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    go_image: golang:1.25-alpine
    build_flags: -v
  variables:
    CGO_ENABLED: 0
```

### Monorepo Multiple Services

```yaml
- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    job_name: test-api
    test_flags: -v -race ./services/api/...
    cache_key: "api-$CI_COMMIT_REF_SLUG"

- component: $CI_SERVER_FQDN/your-group/components/go-test@1.0.0
  inputs:
    job_name: test-worker
    test_flags: -v -race ./services/worker/...
    cache_key: "worker-$CI_COMMIT_REF_SLUG"
```

## Performance Tips

### Caching (Enabled by Default)

The component caches:

- `.go-pkg/` - Go build cache
- `~/go/pkg/mod/` - Go module cache

This provides **40-60% faster** subsequent builds.

### Disable Caching (Not Recommended)

```yaml
- component: .../go-test@1.0.0
  inputs:
    enable_cache: "false"
```

### Custom Cache Key

```yaml
- component: .../go-test@1.0.0
  inputs:
    cache_key: "go-$CI_COMMIT_REF_SLUG-$CI_PROJECT_ID"
```

### Optimize Test Execution

```yaml
- component: .../go-test@1.0.0
  inputs:
    test_flags: -v -race -parallel=8 -count=1  # Disable test caching, use 8 cores
```

## Troubleshooting

### Tests Not Failing Pipeline

**Problem**: Tests fail but pipeline passes

**Solution**: Ensure `allow_test_failure` is `false` (default):

```yaml
- component: .../go-test@1.0.0
  inputs:
    allow_test_failure: "false"  # Default, fails pipeline on test failure
```

### Module Download Fails

**Problem**: `go: module not found` or download errors

**Solution**: Ensure `go.mod` and `go.sum` are committed:

```bash
git add go.mod go.sum
git commit -m "Add Go module files"
```

### Coverage Not Showing in GitLab

**Problem**: Coverage report not visible in MR

**Solution**: Ensure all conditions met:

1. `enable_coverage: "true"`
2. Install `gocover-cobertura` in the pipeline
3. Convert coverage to Cobertura format:

   ```yaml
   inputs:
     test_flags: -v -coverprofile=coverage.out
     enable_coverage: "true"
   ```

### Race Detector Fails

**Problem**: `race: limit on 8128 simultaneously alive goroutines is exceeded`

**Solution**: Increase race detector limits or disable race detection:

```yaml
inputs:
  test_flags: -v  # Remove -race flag
```

Or set environment variable:

```yaml
variables:
  GORACE: "halt_on_error=1 history_size=2"
```

### Cache Not Working

**Problem**: Modules re-download every time

**Solution**: Check that:

1. `enable_cache: "true"` (default)
2. Runner has distributed cache configured
3. Same `cache_key` between runs (default uses branch name)

### Build Fails: Package Not Found

**Problem**: `package ... is not in GOROOT`

**Solution**: Run `go mod tidy` locally and commit:

```bash
go mod tidy
git add go.mod go.sum
git commit -m "Update Go modules"
```

### Test Timeout

**Problem**: Tests timeout after default duration

**Solution**: Increase timeout:

```yaml
- component: .../go-test@1.0.0
  inputs:
    test_flags: -v -timeout=10m
```

## Best Practices

1. **Always Enable Coverage**: Track code coverage trends

   ```yaml
   enable_coverage: "true"
   test_flags: -v -coverprofile=coverage.out
   ```

2. **Enable Test Reports**: See test results in GitLab MR

   ```yaml
   enable_test_report: "true"
   ```

3. **Use Race Detection**: Catch concurrency bugs

   ```yaml
   test_flags: -v -race
   ```

4. **Use Caching**: Speeds up builds significantly

   ```yaml
   enable_cache: "true"  # Default
   ```

5. **Fail Fast**: Don't suppress test failures

   ```yaml
   allow_test_failure: "false"  # Default
   ```

6. **Pin Go Version**: Use specific versions

   ```yaml
   go_image: "golang:1.25.0"
   ```

7. **Use go.mod**: Always commit `go.mod` and `go.sum`

8. **Test All Packages**: Use `./...` to test all packages

   ```yaml
   test_flags: -v ./...
   ```

## Integration with Other Components

### With Buildah Containerize

```yaml
include:
  - component: .../go-test@1.0.0
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
  - component: .../go-test@1.0.0
    inputs:
      stage: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [go-test]

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
  - Native go test support
  - Race detection
  - Dependency caching
  - Test reports with gotestsum
  - Coverage reports with gocover-cobertura
  - Configurable failure handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
