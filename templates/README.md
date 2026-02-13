# GitLab CI/CD Templates

Reusable GitLab CI/CD components for testing, building, and deploying apps in this monorepo.

## Components

Build and test:

- [templates/python-test](python-test/README.md)
- [templates/node-test](node-test/README.md)
- [templates/go-test](go-test/README.md)
- [templates/java-test](java-test/README.md)
- [templates/php-test](php-test/README.md)

Container and deploy:

- [templates/buildah-containerize](buildah-containerize/README.md)
- [templates/image-promote](image-promote/README.md)
- [templates/k8s-deploy](k8s-deploy/README.md)
- [templates/ephemeral-cleanup](ephemeral-cleanup/README.md)

## Usage

Include a component in an app pipeline:

```yaml
include:
  - component: $CI_SERVER_FQDN/your-group/mono-learn/templates/python-test@1.0.0
    inputs:
      stage: test
      job_name: test-python

stages:
  - test
```

## Versioning

- Pin exact versions in production pipelines.
- Use semantic versioning for releases.

## Contributing

- Update component templates in their folders.
- Add or update the component README for new inputs or behavior.
- Tag a release after changes are merged.

## License

Apache 2.0. See [docs/LICENSE.md](docs/LICENSE.md).
