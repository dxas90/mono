# Java Test Component

Executes Java tests with Maven or Gradle, supports caching, Jacoco coverage reporting, and test result artifacts.

## Features

- ✅ **Maven & Gradle Support**: Auto-detects build tool or manual selection
- ☕ **Modern Java**: Supports Java 8 through Java 21+
- ⚡ **Dependency Caching**: 40-60% faster builds with dependency cache
- 📊 **Test Reports**: JUnit XML reports integrated with GitLab UI
- 📈 **Coverage Reports**: Jacoco XML coverage with GitLab visualization
- 🔧 **Configurable**: Custom Maven/Gradle commands and options
- 🚀 **Wrapper Support**: Uses `mvnw`/`gradlew` when available

## Basic Usage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
    inputs:
      stage: test
      job_name: test-java-app

stages:
  - test
```

## Input Parameters

| Input | Default | Required | Description |
| ----- | ------- | -------- | ----------- |
| `stage` | `test` | No | Pipeline stage for the test job |
| `job_name` | `java-test` | No | Name of the test job |
| `java_image` | `eclipse-temurin:21-jdk` | No | Java JDK Docker image |
| `build_tool` | `auto` | No | Build tool (auto, maven, gradle) |
| `maven_command` | `./mvnw clean test` | No | Maven test command |
| `gradle_command` | `./gradlew test` | No | Gradle test command |
| `allow_test_failure` | `false` | No | Continue pipeline even if tests fail |
| `enable_cache` | `true` | No | Enable dependency caching |
| `cache_key` | `$CI_COMMIT_REF_SLUG` | No | Cache key for dependencies |
| `cache_paths` | `[".m2/repository/", ".gradle/"]` | No | Paths to cache |
| `cache_policy` | `pull-push` | No | Cache policy (pull-push, pull, push) |
| `enable_test_report` | `false` | No | Enable JUnit test report generation |
| `test_report_path` | `target/surefire-reports/TEST-*.xml` | No | Path to JUnit XML test reports |
| `enable_coverage` | `false` | No | Enable coverage report (requires Jacoco) |
| `coverage_path` | `target/site/jacoco/jacoco.xml` | No | Path to Jacoco XML coverage report |
| `coverage_format` | `jacoco` | No | Coverage report format (jacoco or cobertura) |
| `needs` | `[]` | No | Job dependencies |

## Output Artifacts

| Artifact | Condition | Description |
| -------- | --------- | ----------- |
| JUnit XML | `enable_test_report=true` | Test results shown in GitLab MR |
| Coverage XML | `enable_coverage=true` | Coverage shown in GitLab MR diff |
| HTML Coverage | `enable_coverage=true` | Browse-able Jacoco HTML report |

## Complete Example with Coverage

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
    inputs:
      stage: test
      job_name: test-with-coverage
      java_image: eclipse-temurin:21-jdk
      build_tool: maven
      maven_command: ./mvnw clean test jacoco:report
      enable_cache: "true"
      enable_test_report: "true"
      test_report_path: target/surefire-reports/TEST-*.xml
      enable_coverage: "true"
      coverage_path: target/site/jacoco/jacoco.xml

stages:
  - test
```

### Setup for Coverage (Maven + Jacoco)

Add to your `pom.xml`:

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.jacoco</groupId>
      <artifactId>jacoco-maven-plugin</artifactId>
      <version>0.8.11</version>
      <executions>
        <execution>
          <goals>
            <goal>prepare-agent</goal>
          </goals>
        </execution>
        <execution>
          <id>report</id>
          <phase>test</phase>
          <goals>
            <goal>report</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

Run locally:

```bash
./mvnw clean test jacoco:report
```

### Setup for Coverage (Gradle + Jacoco)

Add to your `build.gradle`:

```groovy
plugins {
    id 'jacoco'
}

jacoco {
    toolVersion = "0.8.11"
}

test {
    finalizedBy jacocoTestReport
}

jacocoTestReport {
    reports {
        xml.required = true
        html.required = true
    }
}
```

Run locally:

```bash
./gradlew test jacocoTestReport
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

### Gradle with Custom Tasks

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    build_tool: gradle
    gradle_command: ./gradlew clean test jacocoTestReport
    enable_coverage: "true"
    coverage_path: build/reports/jacoco/test/jacocoTestReport.xml
    test_report_path: build/test-results/test/TEST-*.xml
```

### Different Java Version

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    java_image: eclipse-temurin:17-jdk
```

### Maven with Profiles

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    maven_command: ./mvnw clean test -Pci-profile
```

### Skip Integration Tests

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    maven_command: ./mvnw clean test -DskipITs
```

### Integration Tests Only

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    job_name: integration-tests
    maven_command: ./mvnw clean verify -DskipUnitTests
```

### With Custom JVM Options

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    maven_command: ./mvnw clean test
  variables:
    MAVEN_OPTS: "-Xmx2048m -XX:MaxPermSize=512m"
```

### Gradle with Specific Tests

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    gradle_command: ./gradlew test --tests '*UnitTest'
```

### Monorepo Multiple Modules

```yaml
- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    job_name: test-api-module
    maven_command: ./mvnw clean test -pl api -am
    cache_key: "api-$CI_COMMIT_REF_SLUG"

- component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
  inputs:
    job_name: test-worker-module
    maven_command: ./mvnw clean test -pl worker -am
    cache_key: "worker-$CI_COMMIT_REF_SLUG"
```

### With Database Service

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/components/java-test@1.0.0
    inputs:
      maven_command: ./mvnw clean test

java-test:
  services:
    - postgres:15
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: jdbc:postgresql://postgres:5432/testdb
```

## Performance Tips

### Caching (Enabled by Default)

The component caches:

- `.m2/repository/` - Maven local repository
- `.gradle/` - Gradle cache directory

This provides **40-60% faster** subsequent builds.

### Disable Caching (Not Recommended)

```yaml
- component: .../java-test@1.0.0
  inputs:
    enable_cache: "false"
```

### Custom Cache Key

```yaml
- component: .../java-test@1.0.0
  inputs:
    cache_key: "java-$CI_COMMIT_REF_SLUG-$CI_PROJECT_ID"
```

### Maven Parallel Builds

```yaml
- component: .../java-test@1.0.0
  inputs:
    maven_command: ./mvnw clean test -T 4  # Use 4 threads
```

### Gradle Parallel Execution

```yaml
- component: .../java-test@1.0.0
  inputs:
    gradle_command: ./gradlew test --parallel --max-workers=4
```

## Troubleshooting

### Tests Not Failing Pipeline

**Problem**: Tests fail but pipeline passes

**Solution**: Ensure `allow_test_failure` is `false` (default):

```yaml
- component: .../java-test@1.0.0
  inputs:
    allow_test_failure: "false"  # Default, fails pipeline on test failure
```

### Build Tool Not Found

**Problem**: `ERROR: No supported build tool found`

**Solution**: Ensure Maven wrapper (`mvnw`) or Gradle wrapper (`gradlew`) exists:

```bash
# Maven
mvn wrapper:wrapper

# Gradle
gradle wrapper
```

Or specify build tool explicitly:

```yaml
inputs:
  build_tool: maven  # or gradle
```

### Dependencies Not Downloading

**Problem**: `Could not resolve dependencies`

**Solution**: Ensure `pom.xml` or `build.gradle` is valid and dependencies exist:

```bash
# Maven - test locally
./mvnw dependency:resolve

# Gradle - test locally
./gradlew dependencies
```

### Coverage Not Showing in GitLab

**Problem**: Coverage report not visible in MR

**Solution**: Ensure all conditions met:

1. `enable_coverage: "true"`
2. Jacoco plugin configured in `pom.xml` or `build.gradle`
3. Coverage report generated:

   ```bash
   # Maven
   ./mvnw test jacoco:report

   # Gradle
   ./gradlew test jacocoTestReport
   ```

### Cache Not Working

**Problem**: Dependencies re-download every time

**Solution**: Check that:

1. `enable_cache: "true"` (default)
2. Runner has distributed cache configured
3. Same `cache_key` between runs (default uses branch name)

### Out of Memory Errors

**Problem**: `java.lang.OutOfMemoryError: Java heap space`

**Solution**: Increase JVM memory:

```yaml
variables:
  MAVEN_OPTS: "-Xmx2048m"
  # or
  GRADLE_OPTS: "-Xmx2048m"
```

### Test Report Path Wrong (Gradle)

**Problem**: Test reports not found

**Solution**: Use correct Gradle path:

```yaml
inputs:
  test_report_path: build/test-results/test/TEST-*.xml  # Not target/
```

## Best Practices

1. **Always Enable Coverage**: Track code coverage trends

   ```yaml
   enable_coverage: "true"
   maven_command: ./mvnw clean test jacoco:report
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

5. **Use Wrapper Scripts**: Commit `mvnw`/`gradlew` for version consistency

6. **Pin Java Version**: Use specific versions

   ```yaml
   java_image: "eclipse-temurin:21.0.1-jdk"
   ```

7. **Lock Dependencies**: Use dependency lock files

   ```bash
   # Maven - use dependencyManagement
   # Gradle - use dependency locking
   ./gradlew dependencies --write-locks
   ```

## Integration with Other Components

### With Buildah Containerize

```yaml
include:
  - component: .../java-test@1.0.0
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
  - component: .../java-test@1.0.0
    inputs:
      stage: test

  - component: .../buildah-containerize@1.0.0
    inputs:
      stage: build
      needs: [java-test]

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
  - Maven and Gradle support
  - Auto-detection of build tool
  - Dependency caching
  - JUnit test reports
  - Jacoco coverage reports
  - Configurable failure handling

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples/](../../examples/) directory
3. See [WORKFLOW.md](../../WORKFLOW.md) for complete workflows
4. Open an issue in the component repository
