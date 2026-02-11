# PHP Test Component

Executes PHP tests with PHPUnit, supports Composer, caching, coverage reporting, and test result artifacts.

## Features

- ✅ **PHPUnit Integration**: Full PHPUnit test support
- 🐘 **Modern PHP**: Supports PHP 8.0 through PHP 8.3+
- ⚡ **Dependency Caching**: 40-60% faster builds with Composer cache
- 📊 **Test Reports**: JUnit XML reports integrated with GitLab UI
- 📈 **Coverage Reports**: Cobertura/Clover XML coverage with GitLab visualization
- 🔧 **Configurable**: Custom test commands and Composer options
- 🚀 **Xdebug/PCOV Support**: Code coverage with Xdebug or PCOV

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
    inputs:
      stage: test
      job_name: test-php-app

stages:
  - test
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `test` | No | Pipeline stage for the test job |
| `job_name` | `php-test` | No | Name of the test job |
| `php_image` | `php:8.3` | No | PHP Docker image |
| `composer_install` | `true` | No | Run composer install |
| `test_command` | `./vendor/bin/phpunit` | No | Test command to run |
| `allow_test_failure` | `false` | No | Continue pipeline even if tests fail |
| `enable_cache` | `true` | No | Enable dependency caching |
| `cache_key` | `$CI_COMMIT_REF_SLUG` | No | Cache key for dependencies |
| `cache_paths` | `["vendor/", "~/.composer/cache/"]` | No | Paths to cache |
| `cache_policy` | `pull-push` | No | Cache policy (pull-push, pull, push) |
| `enable_test_report` | `false` | No | Enable JUnit test report generation |
| `test_report_path` | `test-report.xml` | No | Path to JUnit XML test report |
| `enable_coverage` | `false` | No | Enable coverage report (requires Xdebug/PCOV) |
| `coverage_path` | `coverage.xml` | No | Path to coverage report (Cobertura/Clover XML) |
| `coverage_format` | `cobertura` | No | Coverage format (cobertura or clover) |
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
  - component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
    inputs:
      stage: test
      job_name: test-with-coverage
      php_image: php:8.3
      composer_install: "true"
      test_command: |
        ./vendor/bin/phpunit \
          --coverage-cobertura coverage.xml \
          --coverage-html coverage/ \
          --log-junit test-report.xml
      enable_cache: "true"
      enable_test_report: "true"
      test_report_path: test-report.xml
      enable_coverage: "true"
      coverage_path: coverage.xml

stages:
  - test
```

### Setup for Coverage (Xdebug)

Create a custom Dockerfile or use `before_script`:

```yaml
- component: .../php-test@1.0.0
  inputs:
    test_command: |
      pecl install xdebug
      docker-php-ext-enable xdebug
      ./vendor/bin/phpunit --coverage-cobertura coverage.xml --log-junit test-report.xml
```

Or use a PHP image with Xdebug pre-installed:

```yaml
inputs:
  php_image: php:8.3-cli
  # Install Xdebug in before_script
```

Add to your `phpunit.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php">
    <coverage>
        <include>
            <directory suffix=".php">src</directory>
        </include>
    </coverage>
    <testsuites>
        <testsuite name="Unit">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

Run locally:

```bash
composer install
./vendor/bin/phpunit --coverage-cobertura coverage.xml --coverage-html coverage/ --log-junit test-report.xml
```

### Setup for Coverage (PCOV - Faster Alternative)

PCOV is faster than Xdebug for coverage:

```yaml
- component: .../php-test@1.0.0
  inputs:
    test_command: |
      pecl install pcov
      docker-php-ext-enable pcov
      ./vendor/bin/phpunit --coverage-cobertura coverage.xml --log-junit test-report.xml
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

### Different PHP Version

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    php_image: php:8.2
```

### Skip Composer Install

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    composer_install: "false"
    test_command: ./vendor/bin/phpunit  # Assumes vendor already exists
```

### With Specific PHPUnit Configuration

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    test_command: ./vendor/bin/phpunit --configuration phpunit.ci.xml
```

### With Test Suite Filtering

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    test_command: ./vendor/bin/phpunit --testsuite Unit
```

### Laravel Application Testing

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    php_image: php:8.3
    test_command: |
      cp .env.testing .env
      php artisan key:generate
      php artisan test --coverage-cobertura coverage.xml
```

### With Database Service

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
    inputs:
      test_command: ./vendor/bin/phpunit

php-test:
  services:
    - mysql:8.0
  variables:
    MYSQL_ROOT_PASSWORD: secret
    MYSQL_DATABASE: testdb
    DB_HOST: mysql
    DB_DATABASE: testdb
    DB_USERNAME: root
    DB_PASSWORD: secret
```

### Pest PHP Testing

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    test_command: ./vendor/bin/pest --coverage --coverage-xml
```

### Monorepo Multiple Packages

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    job_name: test-api
    test_command: cd packages/api && ../../vendor/bin/phpunit
    cache_key: "api-$CI_COMMIT_REF_SLUG"

- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    job_name: test-frontend
    test_command: cd packages/frontend && ../../vendor/bin/phpunit
    cache_key: "frontend-$CI_COMMIT_REF_SLUG"
```

### With PHP Extensions

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    php_image: php:8.3
    test_command: |
      docker-php-ext-install pdo pdo_mysql
      pecl install redis
      docker-php-ext-enable redis
      ./vendor/bin/phpunit
```

### Parallel Test Execution

```yaml
- component: $CI_SERVER_FQDN/your-group/components/php-test@1.0.0
  inputs:
    test_command: ./vendor/bin/paratest --processes=4
```

## Performance Tips

### Caching (Enabled by Default)

The component caches:

- `vendor/` - Composer dependencies
- `~/.composer/cache/` - Composer cache directory

This provides **40-60% faster** subsequent builds.

### Disable Caching (Not Recommended)

```yaml
- component: .../php-test@1.0.0
  inputs:
    enable_cache: "false"
```

### Custom Cache Key

```yaml
- component: .../php-test@1.0.0
  inputs:
    cache_key: "php-$CI_COMMIT_REF_SLUG-$CI_PROJECT_ID"
```

### Use PCOV Instead of Xdebug

PCOV is 2-3x faster for code coverage:

```bash
pecl install pcov
docker-php-ext-enable pcov
```

## Troubleshooting

### Tests Not Failing Pipeline

**Problem**: Tests fail but pipeline passes

**Solution**: Ensure `allow_test_failure` is `false` (default):

```yaml
- component: .../php-test@1.0.0
  inputs:
    allow_test_failure: "false"  # Default, fails pipeline on test failure
```

### Composer Install Fails

**Problem**: `Your requirements could not be resolved`

**Solution**: Ensure `composer.json` and `composer.lock` are committed:

```bash
composer install
git add composer.json composer.lock
git commit -m "Add Composer lock file"
```

### PHPUnit Not Found

**Problem**: `./vendor/bin/phpunit: No such file or directory`

**Solution**: Ensure PHPUnit is in `composer.json`:

```json
{
  "require-dev": {
    "phpunit/phpunit": "^10.0"
  }
}
```

### Coverage Not Showing in GitLab

**Problem**: Coverage report not visible in MR

**Solution**: Ensure all conditions met:

1. `enable_coverage: "true"`
2. Xdebug or PCOV installed
3. Coverage command generates XML:

   ```bash
   ./vendor/bin/phpunit --coverage-cobertura coverage.xml
   ```

### Cache Not Working

**Problem**: Dependencies re-install every time

**Solution**: Check that:

1. `enable_cache: "true"` (default)
2. Runner has distributed cache configured
3. Same `cache_key` between runs (default uses branch name)

### Memory Limit Errors

**Problem**: `Allowed memory size exhausted`

**Solution**: Increase PHP memory limit:

```yaml
- component: .../php-test@1.0.0
  inputs:
    test_command: php -d memory_limit=512M ./vendor/bin/phpunit
```

### Xdebug Installation Fails

**Problem**: `ERROR: failed to install xdebug`

**Solution**: Use appropriate Xdebug version for PHP:

```yaml
test_command: |
  pecl install xdebug-3.3.1  # Specify version
  docker-php-ext-enable xdebug
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

5. **Lock Dependencies**: Always commit `composer.lock`

6. **Use Specific PHP Versions**: Pin to exact versions

   ```yaml
   php_image: "php:8.3.2"
   ```

7. **Use PCOV for Coverage**: Faster than Xdebug

8. **Configure phpunit.xml**: Store test configuration in repo

## Integration with Other Components

### With Buildah Containerize

```yaml
include:
  - component: .../php-test@1.0.0
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
  - component: .../php-test@1.0.0
    inputs:
      stage: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [php-test]

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
  - PHPUnit support
  - Composer integration
  - Dependency caching
  - JUnit test reports
  - Coverage reports (Xdebug/PCOV)
  - Configurable failure handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
