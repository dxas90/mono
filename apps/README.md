# Applications

This folder contains Git submodules for each application. The submodule definitions live in [.gitmodules](../.gitmodules).

## Included apps

| App | Path | Description |
| --- | --- | --- |
| learn-go | [apps/learn-go](learn-go/README.md) | Go API service |
| learn-python | [apps/learn-python](learn-python/README.md) | Python API service |
| learn-rust | [apps/learn-rust](learn-rust/README.md) | Rust API service |
| mesh | [apps/mesh](mesh/README.md) | GraphQL Mesh gateway |
| ui | [apps/ui](ui/README.md) | Web UI for API exploration |

## Common tasks

### Update all submodules

```bash
git submodule update --init --recursive --remote
```

### Add a new app

```bash
git submodule add https://github.com/your-org/your-app.git apps/your-app
```

Then commit the updated [.gitmodules](../.gitmodules) and the new submodule path.

### Pin a submodule to a specific commit

```bash
cd apps/your-app
git checkout <commit-sha>
cd ../..
git add apps/your-app
```

## Notes

- The repo uses a Git hook in [mise.toml](../mise.toml) to keep submodules current on entry.
- Each app owns its own CI config and runtime documentation in its README.
