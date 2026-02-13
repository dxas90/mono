# Contributing to CI/CD Components

Thank you for your interest in contributing to this component library!

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in the issue tracker
2. Create a new issue with a clear description
3. Include steps to reproduce (for bugs)
4. Suggest the expected behavior

### Proposing New Components

Before creating a new component:

1. Check if similar functionality already exists
2. Open an issue to discuss the component
3. Get feedback from maintainers
4. Create a merge request with the implementation

### Component Development Guidelines

#### 1. Component Structure

```text
templates/
  my-component/
    template.yml      # Component definition
    README.md         # Component documentation
    test.sh          # Optional test script
```

#### 2. Component Template Format

```yaml
spec:
  inputs:
    stage:
      default: test
      description: "Pipeline stage"
    job_name:
      default: "my-job"
      description: "Job name"
    # ... more inputs
---
"$[[ inputs.job_name ]]":
  stage: $[[ inputs.stage ]]
  image: ubuntu:latest
  script:
    - echo "Running component"
  needs: $[[ inputs.needs ]]
```

#### 3. Best Practices

- **Use inputs for configuration**: Avoid hardcoded values
- **Provide sensible defaults**: Make components easy to use
- **Document all inputs**: Clear descriptions in spec section
- **Avoid global keywords**: Don't use `default:`, `workflow:`, etc.
- **Use unique job names**: Support job name customization via inputs
- **Test thoroughly**: Include tests in the component directory
- **Keep components focused**: One component should do one thing well

#### 4. Documentation Requirements

Each component must have:

- Clear description of purpose
- Usage example
- Input parameters table
- Output artifacts (if any)
- Version compatibility notes

Example README.md:

```markdown
# Component Name

Brief description of what the component does.

## Usage

\`\`\`yaml
include:
  - component: $CI_SERVER_FQDN/group/components/my-component@1.0.0
    inputs:
      stage: test
\`\`\`

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| stage | test | Pipeline stage |

## Outputs

- Creates artifact X
- Exports variable Y
```

#### 5. Testing Components

Test your component locally:

```bash
# Create a test project
git clone your-component-project
cd your-component-project

# Create a test pipeline
cat > .gitlab-ci.yml << 'EOF'
include:
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/my-component@$CI_COMMIT_SHA
    inputs:
      stage: test

stages: [test]
EOF

# Commit and push to trigger pipeline
git add .gitlab-ci.yml
git commit -m "Test component"
git push
```

#### 6. Code Review Process

1. Create a feature branch: `git checkout -b feature/my-component`
2. Make your changes
3. Test your component
4. Update documentation
5. Create a merge request
6. Address review feedback
7. Wait for approval from maintainers

#### 7. Release Process

Maintainers will handle releases:

1. Merge approved changes to main branch
2. Create a new tag with semantic versioning
3. Pipeline automatically creates a release
4. Component is published to the catalog

### Semantic Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes, backward compatible

Examples:

- Adding a required input: MAJOR
- Adding an optional input: MINOR
- Fixing a bug: PATCH
- Improving documentation: PATCH

### Security

- Never commit secrets or credentials
- Use masked variables for sensitive data
- Audit component dependencies
- Follow least-privilege principles
- Report security issues privately to maintainers

### Component Naming Conventions

- Use lowercase with hyphens: `my-component`
- Be descriptive: `docker-build` not `build`
- Avoid redundancy: `test-python` not `python-test-component`

### File Organization

```text
components/
├── README.md                    # Main documentation
├── LICENSE.md                   # License
├── MIGRATION.md                 # Migration guide
├── CONTRIBUTING.md              # This file
├── .gitlab-ci.yml              # Test and release pipeline
├── templates/
│   ├── component-1/
│   │   ├── template.yml
│   │   ├── README.md
│   │   └── test.sh
│   ├── component-2.yml         # Simple components use single file
│   └── ...
└── examples/
    ├── .gitlab-ci-example-1.yml
    └── ...
```

## Questions?

- Open an issue for general questions
- Tag maintainers for urgent issues
- Check existing documentation first

Thank you for contributing! 🎉
