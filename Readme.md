# Monorepo Project

This repository serves as a monorepo containing multiple applications, each housed within its own Git submodule under the `apps` directory. Each submodule has its own GitLab CI/CD pipeline, tailored to the specific programming language and framework of the application.

## Submodules

The following submodules are included in this repository:

* [acme-lambda-cloudflare-go](https://github.com/dxas90/acme-lambda-cloudflare-go.git) – Go-based AWS Lambda function for Cloudflare integration
* [django-postgresql-gunicorn](https://github.com/dxas90/django-postgresql-gunicorn.git) – Django application with PostgreSQL and Gunicorn setup
* [full-workflow](https://github.com/dxas90/full-workflow.git) – Comprehensive application demonstrating a full CI/CD pipeline
* [learn](https://github.com/dxas90/learn.git) – Educational application for learning purposes
* [network-stats](https://github.com/dxas90/network-stats.git) – Application for monitoring and displaying network statistics
* [pg-database-tester](https://github.com/dxas90/pg-database-tester.git) – Tool for testing PostgreSQL databases
* [sinatra-mysql-puma](https://github.com/dxas90/sinatra-mysql-puma.git) – Sinatra application with MySQL and Puma setup

## Git Submodule Setup

To initialize the submodules, run the following commands:

```bash
git submodule init
git submodule update
```

Alternatively, you can clone the repository with all submodules initialized:

```bash
git clone --recurse-submodules https://gitlab.com/your-username/your-repo.git
```

## GitLab CI/CD Configuration

Each submodule contains its own `.gitlab-ci.yml` file, defining the CI/CD pipeline specific to the application's language and framework. The pipelines generally consist of the following stages:

1. **Build** – Compile the application
2. **Test** – Run unit and integration tests
3. **Deploy** – Deploy the application to the appropriate environment

### Submodule-Specific Pipelines

* **acme-lambda-cloudflare-go**: Utilizes Go-specific tools and AWS Lambda deployment strategies.
* **django-postgresql-gunicorn**: Employs Python, Django, and PostgreSQL-specific configurations.
* **full-workflow**: Demonstrates a comprehensive CI/CD pipeline with multiple stages and environments.
* **learn**: Focuses on educational content with a simplified pipeline.
* **network-stats**: Implements monitoring tools and network-related configurations.
* **pg-database-tester**: Specializes in database testing with PostgreSQL.
* **sinatra-mysql-puma**: Configures a Ruby Sinatra application with MySQL and Puma.

## CI/CD Pipeline Triggering

To ensure that only the relevant pipelines are triggered when changes are made, the main repository's `.gitlab-ci.yml` file includes logic to detect changes within specific subdirectories. For example:

```yaml
stages:
  - check

check_changes:
  stage: check
  script:
    - |
      if git diff --name-only $CI_COMMIT_BEFORE_SHA $CI_COMMIT_SHA | grep -q '^apps/acme-lambda-cloudflare-go/'; then
        echo "Changes detected in acme-lambda-cloudflare-go"
        # Trigger the submodule's pipeline
      fi
```

This approach ensures that only the pipelines for the affected submodules are executed, optimizing CI/CD resources and time.

## Accessing Submodule Repositories

Each submodule is a separate Git repository. To make changes to a submodule, navigate to its directory and follow the standard Git workflow:

```bash
cd apps/acme-lambda-cloudflare-go
git checkout -b new-feature
# Make changes
git commit -am "Add new feature"
git push origin new-feature
```

After pushing changes to a submodule, update the main repository to reflect the new commit:

```bash
cd ../../
git add apps/acme-lambda-cloudflare-go
git commit -m "Update submodule acme-lambda-cloudflare-go"
git push origin main
```

## Best Practices

* **Submodule Updates**: Regularly update submodules to incorporate the latest changes from their respective repositories.
* **CI/CD Efficiency**: Utilize GitLab's `rules` and `only/except` directives to fine-tune when pipelines should run, ensuring efficiency.
* **Documentation**: Maintain clear documentation within each submodule to facilitate understanding and collaboration.

## Troubleshooting

* **Submodule Initialization Issues**: If you encounter problems initializing submodules, ensure that the `.gitmodules` file is correctly configured and that you have the necessary permissions to access the submodule repositories.
* **CI/CD Pipeline Failures**: Review the pipeline logs for specific error messages. Common issues may include missing dependencies, incorrect environment configurations, or permission errors.

## Conclusion

This monorepo structure, utilizing Git submodules and tailored GitLab CI/CD pipelines, provides a modular and efficient approach to managing multiple applications within a single repository. By isolating each application in its own submodule, we can maintain clear boundaries, simplify dependency management, and optimize our CI/CD processes.

