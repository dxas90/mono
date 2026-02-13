# Mono Learn

Monorepo for GitOps-driven Kubernetes deployments plus multiple application submodules and reusable GitLab CI/CD templates.

## Repository layout

```text
mono-learn/
├── apps/         # Application submodules
├── bootstrap/    # Flux + cluster bootstrap manifests
├── clusters/     # Cluster-specific Flux sync and vars
├── base/         # Base app definitions for GitOps
├── overlays/     # Environment overlays (dev/stg/prod)
├── templates/    # GitLab CI/CD component templates
└── docs/         # Project documentation
```

## Quick start

1. Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/dxas90/mono-learn.git
cd mono-learn
```

1. Update submodules later if needed:

```bash
git submodule update --init --recursive --remote
```

1. Review the bootstrap flow before applying anything to a cluster:

- See [bootstrap/README.md](bootstrap/README.md)
- See [clusters/README.md](clusters/README.md)

## Applications

| App | Path | Description |
| --- | --- | --- |
| learn-go | [apps/learn-go](apps/learn-go/README.md) | Go API service |
| learn-python | [apps/learn-python](apps/learn-python/README.md) | Python API service |
| learn-rust | [apps/learn-rust](apps/learn-rust/README.md) | Rust API service |
| mesh | [apps/mesh](apps/mesh/README.md) | GraphQL Mesh gateway |
| ui | [apps/ui](apps/ui/README.md) | Web UI for API exploration |

Submodules are defined in [.gitmodules](.gitmodules).

## GitOps structure

- Bootstrap Flux and shared CRDs from [bootstrap/README.md](bootstrap/README.md)
- Define per-app base resources in [base/README.md](base/README.md)
- Apply environment-specific overlays in [overlays/README.md](overlays/README.md)
- Point clusters at overlays with Flux sync manifests in [clusters/README.md](clusters/README.md)

## GitLab CI/CD templates

Reusable pipeline components live under [templates/README.md](templates/README.md). Each template folder documents inputs, outputs, and example usage.

## Documentation

Start with [templates/docs/GETTING_STARTED.md](templates/docs/GETTING_STARTED.md) and [templates/docs/WORKFLOW.md](templates/docs/WORKFLOW.md).

## License

Apache 2.0. See [LICENSE](LICENSE).
