# Python Test Component

Executes Python tests with pytest, supports caching, coverage reporting, and test result artifacts.

## Features

- ✅ **Pytest Integration**: Runs Python tests with full pytest support
- ⚡ **Dependency Caching**: 40-60% faster builds with pip cache
- 📊 **Test Reports**: JUnit XML reports integrated with GitLab UI
- 📈 **Coverage Reports**: Cobertura XML coverage with GitLab visualization
- 🔧 **Configurable**: All major options exposed as inputs
- 🐍 **Python 3.x**: Supports all modern Python versions

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: test-python-app

stages:
  - test
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `test` | No | Pipeline stage for the test job |
| `job_name` | `python-test` | No | Name of the test job |
| `python_image` | `python:3.12` | No | Python Docker image |
| `requirements_file` | `requirements.txt` | No | Path to requirements.txt |
| `test_command` | `pytest` | No | Test command to run |
| `allow_test_failure` | `false` | No | Continue pipeline even if tests fail |
| `enable_cache` | `true` | No | Enable dependency caching |
| `cache_key` | `$CI_COMMIT_REF_SLUG` | No | Cache key for dependencies |
| `cache_paths` | `[".venv/", "~/.cache/pip/"]` | No | Paths to cache |
| `cache_policy` | `pull-push` | No | Cache policy (pull-push, pull, push) |
| `enable_test_report` | `false` | No | Enable JUnit test report generation |
| `test_report_path` | `test-report.xml` | No | Path to JUnit XML test report |
| `enable_coverage` | `false` | No | Enable coverage report generation |
| `coverage_path` | `coverage.xml` | No | Path to coverage report |
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
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      stage: test
      job_name: test-with-coverage
      python_image: python:3.12
      requirements_file: requirements.txt
      test_command: pytest --cov=src --cov-report=xml --cov-report=html --junitxml=test-report.xml
      enable_cache: "true"
      enable_test_report: "true"
      test_report_path: test-report.xml
      enable_coverage: "true"
      coverage_path: coverage.xml

stages:
  - test
```

### Setup for Coverage

Add to your `requirements.txt`:

```text
pytest
pytest-cov
```

Run locally:

```bash
pytest --cov=src --cov-report=xml --cov-report=html --junitxml=test-report.xml
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

### Custom Python Version

```yaml
- component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
  inputs:
    python_image: python:3.11
    requirements_file: requirements-dev.txt
```

### Multiple Test Jobs

```yaml
# Unit tests
- component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
  inputs:
    job_name: unit-tests
    test_command: pytest tests/unit/

# Integration tests
- component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
  inputs:
    job_name: integration-tests
    test_command: pytest tests/integration/
    needs: [unit-tests]
```

### With Database Service

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/python-test@1.0.0
    inputs:
      test_command: pytest tests/

test-python-app:
  services:
    - postgres:15
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: postgresql://test:test@postgres:5432/testdb
```

## Performance Tips

### Caching (Enabled by Default)

The component caches:

- `.venv/` - Virtual environments
- `~/.cache/pip/` - Pip cache

This provides **40-60% faster** subsequent builds.

### Disable Caching (Not Recommended)

```yaml
- component: .../python-test@1.0.0
  inputs:
    enable_cache: "false"
```

### Custom Cache Key

```yaml
- component: .../python-test@1.0.0
  inputs:
    cache_key: "python-$CI_COMMIT_REF_SLUG-$CI_PROJECT_ID"
```

## Troubleshooting

### Tests Not Failing Pipeline

**Problem**: Tests fail but pipeline passes

**Solution**: Ensure `allow_test_failure` is `false` (default):

```yaml
- component: .../python-test@1.0.0
  inputs:
    allow_test_failure: "false"  # Default, fails pipeline on test failure
```

### Missing Dependencies

**Problem**: Dependencies not found

**Solution**: Verify `requirements.txt` exists and path is correct:

```yaml
- component: .../python-test@1.0.0
  inputs:
    requirements_file: requirements.txt  # or custom path
```

### Coverage Not Showing in GitLab

**Problem**: Coverage report not visible in MR

**Solution**: Ensure all three conditions met:

1. `enable_coverage: "true"`
2. `coverage_path` points to Cobertura XML file
3. Test command generates coverage in Cobertura format:

   ```shell
   pytest --cov=src --cov-report=xml
   ```

### Cache Not Working

**Problem**: Dependencies re-install every time

**Solution**: Check that:

1. `enable_cache: "true"` (default)
2. Runner has distributed cache configured
3. Same `cache_key` between runs (default uses branch name)

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

5. **Version Lock Dependencies**: Use `requirements.txt` with pinned versions

## Integration with Other Components

### With Buildah Containerize

```yaml
include:
  - component: .../python-test@1.0.0
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

stages:
  - test
  - build
  - deploy
```

## Version History

- **1.0.0**: Initial release
  - Pytest support
  - Dependency caching
  - Test reports
  - Coverage reports
  - Configurable failure handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
