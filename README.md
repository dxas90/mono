# Mono Learn

Monorepo for GitOps-driven Kubernetes deployments plus multiple application submodules and reusable GitLab CI/CD templates.

## Repository layout

```text
mono-learn/
├── apps/         # Application submodules
├── base/         # Base app definitions for GitOps
├── bootstrap/    # Flux + cluster bootstrap manifests
├── charts/       # Helm chart with tests
├── clusters/     # Cluster-specific Flux sync and vars
├── overlays/     # Environment overlays (dev/stg/prod)
├── scripts/      # Helper scripts
└── templates/    # GitLab CI/CD component templates
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

The applications live in their own repositories, mounted as git submodules under `apps/`. See [apps/README.md](apps/README.md) for the list of apps and their repositories.

| App | Path | Description |
| --- | --- | --- |
| learn-go | `apps/learn-go` | Go API service |
| learn-python | `apps/learn-python` | Python API service |
| learn-rust | `apps/learn-rust` | Rust API service |
| mesh | `apps/mesh` | GraphQL Mesh gateway |
| ui | `apps/ui` | Web UI for API exploration |

Submodules are defined in [.gitmodules](.gitmodules).

## GitOps structure

- Bootstrap Flux and shared CRDs from [bootstrap/README.md](bootstrap/README.md)
- Define per-app base resources in [base/README.md](base/README.md)
- Apply environment-specific overlays in [overlays/README.md](overlays/README.md)
- Point clusters at overlays with Flux sync manifests in [clusters/README.md](clusters/README.md)

## GitLab CI/CD templates

Reusable pipeline components live under [templates/README.md](templates/README.md). Each template folder documents inputs, outputs, and example usage.

## Documentation

- [CLAUDE.md](CLAUDE.md) — repository conventions and agent guidance
- [apps/README.md](apps/README.md) — application submodules
- [base/README.md](base/README.md) — base app definitions
- [bootstrap/README.md](bootstrap/README.md) — Flux + cluster bootstrap
- [clusters/README.md](clusters/README.md) — cluster sync and vars
- [overlays/README.md](overlays/README.md) — environment overlays
- [scripts/README.md](scripts/README.md) — helper scripts
- [templates/README.md](templates/README.md) — GitLab CI/CD component templates

Guides under `templates/docs/`:

- [templates/docs/ARCHITECTURE.md](templates/docs/ARCHITECTURE.md)
- [templates/docs/CONTRIBUTING.md](templates/docs/CONTRIBUTING.md)
- [templates/docs/GETTING_STARTED.md](templates/docs/GETTING_STARTED.md)
- [templates/docs/MIGRATION.md](templates/docs/MIGRATION.md)
- [templates/docs/QUICKREF.md](templates/docs/QUICKREF.md)
- [templates/docs/SECURITY.md](templates/docs/SECURITY.md)
- [templates/docs/SUMMARY.md](templates/docs/SUMMARY.md)
- [templates/docs/WORKFLOW.md](templates/docs/WORKFLOW.md)

## License

Apache 2.0. See [LICENSE](LICENSE).
