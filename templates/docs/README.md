# CI/CD Components Library

A collection of reusable GitLab CI/CD components for building, testing, and deploying applications in a monorepo environment.

## Components

This project provides the following components:

### Build & Test Components

- **[Python Test](templates/python-test/)** - Test Python applications with pip/pytest
- **[Node.js Test](templates/node-test/)** - Test Node.js applications with pnpm
- **[Go Test](templates/go-test/)** - Test Go applications
- **[Java Test](templates/java-test/)** - Test Java applications with Maven/Gradle
- **[PHP Test](templates/php-test/)** - Test PHP applications with Composer/PHPUnit

### Container Components

- **[Buildah Containerize](templates/buildah-containerize/)** - Build and push container images using Buildah
- **[Image Promote](templates/image-promote/)** - Promote container images between tags

### Deployment Components

- **[Kubernetes Deploy](templates/k8s-deploy/)** - Deploy applications to Kubernetes with environment-based routing
- **[Ephemeral Cleanup](templates/ephemeral-cleanup/)** - Clean up ephemeral environments

### Utility Components

- **[Notify](templates/notify/)** - Send notifications (placeholder for Slack/Teams/etc)

## Usage

To use a component from this library, include it in your `.gitlab-ci.yml`:

```yaml
include:
  - component: $CI_SERVER_FQDN/<your-group>/components/buildah-containerize@1.0.0
    inputs:
      stage: build
      dockerfile_path: Dockerfile
      image_repository: $CI_REGISTRY_IMAGE

stages: [test, build, deploy]
```

### Version Selection

- Use specific versions: `@1.0.0` (recommended)
- Use partial versions: `@1.0` (latest 1.0.x)
- Use major version: `@1` (latest 1.x.x)
- Use latest: `@~latest` (not recommended for production)

## Best Practices

1. **Pin to specific versions** in production pipelines
2. **Use semantic versioning** when releasing components
3. **Test components** before releasing new versions
4. **Review component source** before using in your pipelines
5. **Use minimal permissions** for tokens and credentials

## Contributing

1. Make changes to components in the `templates/` directory
2. Test your changes using the component CI pipeline
3. Create a merge request with your changes
4. Once merged, create a new release tag with semantic versioning

## License

MIT License - See [LICENSE.md](LICENSE.md) for details
