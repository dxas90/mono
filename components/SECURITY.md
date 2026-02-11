# Security Best Practices

This document outlines security best practices when using GitLab CI/CD components in this repository.

## Table of Contents

1. [Secrets Management](#secrets-management)
2. [Container Security](#container-security)
3. [Registry Authentication](#registry-authentication)
4. [Kubernetes Security](#kubernetes-security)
5. [Code Security](#code-security)
6. [Pipeline Security](#pipeline-security)
7. [Network Security](#network-security)
8. [Incident Response](#incident-response)

---

## Secrets Management

### DO: Use GitLab CI/CD Variables

Store all sensitive data in GitLab CI/CD variables:

**Settings → CI/CD → Variables**

```yaml
# Good - using GitLab variables
variables:
  DATABASE_URL: $DB_CONNECTION_STRING
  API_KEY: $EXTERNAL_API_KEY
```

### DO: Mark Variables as Protected and Masked

- **Protected**: Only available on protected branches/tags
- **Masked**: Values hidden in job logs

```
NPM_TOKEN          [Protected] [Masked]
KUBE_CONFIG        [Protected] [Masked]
DATABASE_PASSWORD  [Protected] [Masked]
```

### DON'T: Commit Secrets

Never commit secrets to source code:

```yaml
# BAD - hardcoded secret
database:
  password: "MyP@ssw0rd123"

# GOOD - using variable
database:
  password: $DATABASE_PASSWORD
```

### DO: Use File-Type Variables

For multi-line secrets (certificates, kubeconfig):

1. Create file-type variable in GitLab
2. Reference in pipeline:

```yaml
before_script:
  - export KUBECONFIG=$KUBE_CONFIG_FILE
```

### DO: Rotate Secrets Regularly

- Rotate passwords every 90 days
- Rotate API tokens every 180 days
- Rotate SSH keys annually
- Revoke tokens immediately when team member leaves

### DON'T: Log Secrets

Avoid echoing variables that might contain secrets:

```yaml
# BAD
script:
  - echo "Connecting to $DATABASE_URL"

# GOOD
script:
  - echo "Connecting to database..."
  - psql $DATABASE_URL -c "SELECT 1"
```

---

## Container Security

### DO: Use Specific Image Tags

Never use `latest` tag in production:

```dockerfile
# BAD
FROM python:latest
FROM node:latest

# GOOD
FROM python:3.12.1-slim
FROM node:22.1.0-alpine
```

### DO: Scan Images for Vulnerabilities

Integrate security scanning into your pipeline:

```yaml
security-scan:
  stage: scan
  image: aquasec/trivy:latest
  script:
    - trivy image --severity HIGH,CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  allow_failure: false  # Fail pipeline on vulnerabilities
```

### DO: Use Minimal Base Images

Reduce attack surface with minimal images:

```dockerfile
# Better - slim variant
FROM python:3.12-slim

# Best - distroless (no shell, package manager)
FROM gcr.io/distroless/python3
```

### DO: Run as Non-Root User

```dockerfile
# Create non-root user
RUN useradd -m -u 1000 appuser

# Switch to non-root user
USER appuser

# Run application
CMD ["python", "app.py"]
```

### DO: Enable TLS Verification

Always verify TLS certificates:

```yaml
- component: .../buildah-containerize@1.0.0
  inputs:
    tls_verify: "true"  # Default, always keep enabled
```

Only disable in isolated, air-gapped networks.

### DON'T: Include Secrets in Images

Never bake secrets into container images:

```dockerfile
# BAD
ENV API_KEY="secret123"
COPY .env /app/.env

# GOOD - inject at runtime
# (secrets provided via Kubernetes secrets or environment variables)
```

### DO: Use Multi-Stage Builds

Reduce final image size and attack surface:

```dockerfile
# Build stage
FROM golang:1.25 AS builder
WORKDIR /app
COPY . .
RUN go build -o main .

# Production stage
FROM gcr.io/distroless/base
COPY --from=builder /app/main /
CMD ["/main"]
```

---

## Registry Authentication

### DO: Use Password-Stdin

Never pass passwords as command-line arguments:

```yaml
# BAD - password visible in logs/process list
buildah login -u user --password "$PASSWORD" registry.com

# GOOD - password from stdin
echo "$PASSWORD" | buildah login -u user --password-stdin registry.com
```

### DO: Use Short-Lived Tokens

Use `$CI_JOB_TOKEN` for registry authentication when possible:

```yaml
variables:
  CI_REGISTRY_USER: gitlab-ci-token
  CI_REGISTRY_PASSWORD: $CI_JOB_TOKEN
```

This token:

- Expires after job completes
- Scoped to current project
- Automatically rotated

### DO: Configure Image Pull Secrets

For Kubernetes deployments:

```bash
kubectl create secret docker-registry gitlab-registry \
  --docker-server=$CI_REGISTRY \
  --docker-username=$CI_DEPLOY_USER \
  --docker-password=$CI_DEPLOY_PASSWORD \
  -n production
```

Reference in deployment:

```yaml
spec:
  imagePullSecrets:
    - name: gitlab-registry
```

---

## Kubernetes Security

### DO: Use Namespace Isolation

Separate environments with namespaces:

```yaml
- Ephemeral: myapp-feature-branch
- Staging: staging
- Production: production
```

### DO: Apply RBAC Policies

Principle of least privilege:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gitlab-deploy
  namespace: production
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "update", "patch"]
  # No delete permission in production
```

### DO: Use Network Policies

Restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - port: 8080
```

### DO: Set Resource Limits

Prevent resource exhaustion:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### DO: Configure Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### DO: Use Secrets, Not ConfigMaps

For sensitive data:

```bash
# Create secret
kubectl create secret generic app-secrets \
  --from-literal=db-password=secret123 \
  -n production

# Reference in deployment
envFrom:
  - secretRef:
      name: app-secrets
```

### DON'T: Expose Secrets in Environment Variables

Use volume mounts instead:

```yaml
volumeMounts:
  - name: secrets
    mountPath: "/etc/secrets"
    readOnly: true
volumes:
  - name: secrets
    secret:
      secretName: app-secrets
```

---

## Code Security

### DO: Pin Dependencies

Lock dependency versions:

```yaml
# Python - requirements.txt
Flask==3.0.0
requests==2.31.0

# Node.js - package-lock.json (commit this)
npm ci --frozen-lockfile

# Go - go.sum (commit this)
go mod verify
```

### DO: Scan Dependencies

Check for known vulnerabilities:

```yaml
dependency-scan:
  stage: test
  script:
    # Python
    - pip install safety
    - safety check

    # Node.js
    - npm audit

    # Go
    - go list -json -m all | docker run --rm -i sonatypes/nancy:latest sleuth
```

### DO: Use Static Analysis

```yaml
sast:
  stage: test
  script:
    # Python
    - pip install bandit
    - bandit -r src/

    # Node.js
    - npm install -g eslint eslint-plugin-security
    - eslint --plugin security src/

    # Go
    - go install github.com/securego/gosec/v2/cmd/gosec@latest
    - gosec ./...
```

### DO: Validate Input

Never trust user input:

```python
# Python - use parameterized queries
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# NOT THIS
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

### DON'T: Use eval() or exec()

```python
# BAD
eval(user_input)
exec(user_code)

# GOOD - use safe alternatives
import ast
ast.literal_eval(user_input)  # Only evaluates literals
```

---

## Pipeline Security

### DO: Validate CI/CD Configuration

```yaml
lint-gitlab-ci:
  stage: validate
  image: registry.gitlab.com/pipeline-components/gitlab-ci-lint:latest
  script:
    - gitlab-ci-lint .gitlab-ci.yml
```

### DO: Require Manual Approval for Production

```yaml
deploy-production:
  stage: deploy
  when: manual  # Require explicit approval
  only:
    - tags
  environment:
    name: production
```

### DO: Use Protected Branches

Configure in **Settings → Repository → Protected branches**:

- Protect `main` and `production` branches
- Require MR approval
- Restrict force push
- Require status checks

### DO: Enable Merge Request Approvals

**Settings → Merge Requests → Merge request approvals**:

- Require 1-2 approvals
- Prevent author approval
- Require code owner approval

### DON'T: Run Untrusted Code

Be cautious with:

```yaml
# Potentially dangerous
script:
  - curl https://install.sh | sh
  - eval "$(some-command)"
```

Always review scripts before executing.

### DO: Use Job Token Scope

Limit token access:

**Settings → CI/CD → Token Access**:

- Limit to specific projects
- Disable for external contributions

---

## Network Security

### DO: Use Private Runners

For sensitive projects, use self-managed runners:

- Runs in your infrastructure
- No data sent to GitLab servers (except metadata)
- Full control over environment

### DO: Configure Runner Tags

Separate runners by security level:

```yaml
deploy-production:
  tags:
    - production
    - secure
    - self-managed
```

### DO: Enable TLS Everywhere

```yaml
# Container registry
tls_verify: "true"

# Database connections
DATABASE_URL: postgresql://user:pass@host:5432/db?sslmode=require

# API calls
requests.get(url, verify=True)
```

### DON'T: Expose Internal Services

Use ingress with authentication:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
```

---

## Incident Response

### DO: Monitor Pipeline Activity

Set up alerts for:

- Failed security scans
- Unexpected production deployments
- Large secret downloads
- Unusual pipeline patterns

### DO: Audit CI/CD Changes

Review audit logs regularly:

**Admin → Audit Events**

- Variable changes
- Runner modifications
- Pipeline trigger sources
- Protected branch changes

### DO: Have Rollback Plan

```yaml
rollback-production:
  stage: rollback
  when: manual
  script:
    - kubectl rollout undo deployment/app -n production
  environment:
    name: production
```

### DO: Document Incidents

Maintain incident log:

- What happened
- When it was detected
- How it was resolved
- Preventive measures

### DO: Rotate Compromised Secrets

If a secret is exposed:

1. Rotate immediately
2. Revoke old secret
3. Audit access logs
4. Update all systems
5. Document incident

---

## Security Checklist

### Pre-Deployment

- [ ] All secrets stored in GitLab variables, not code
- [ ] Variables marked as protected and masked
- [ ] Container images scanned for vulnerabilities
- [ ] Dependencies pinned to specific versions
- [ ] SAST scanning enabled
- [ ] TLS verification enabled
- [ ] Non-root user in containers
- [ ] Resource limits set in Kubernetes
- [ ] RBAC policies applied
- [ ] Network policies configured
- [ ] Manual approval required for production

### Regular Maintenance

- [ ] Review and rotate secrets quarterly
- [ ] Update base images monthly
- [ ] Scan dependencies weekly
- [ ] Audit access logs monthly
- [ ] Review RBAC permissions quarterly
- [ ] Test disaster recovery procedures

### After Incidents

- [ ] Rotate affected secrets immediately
- [ ] Review audit logs
- [ ] Update security policies
- [ ] Document lessons learned
- [ ] Notify stakeholders
- [ ] Implement preventive controls

---

## Resources

- [GitLab Security Best Practices](https://docs.gitlab.com/ee/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

## Reporting Security Issues

If you discover a security vulnerability in these components:

1. **DO NOT** create a public issue
2. Email security team directly
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
4. Allow reasonable time for fix before disclosure

---

## Version History

- **1.0.0**: Initial security documentation
  - Secrets management
  - Container security
  - Kubernetes security
  - Pipeline security
  - Incident response

---

**Remember**: Security is not a one-time task, it's an ongoing process. Stay vigilant, keep learning, and always question assumptions.
