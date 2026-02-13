# Overlays

Environment-specific overlays for application deployments. These kustomize overlays compose the base app definitions from [base/README.md](../base/README.md) with environment-specific changes.

## Structure

```text
overlays/
├── dev/
│   ├── learn-go/
│   ├── learn-python/
│   ├── learn-rust/
│   ├── mesh/
│   └── ui/
├── stg/
└── prod/
```

## How it fits

- Each overlay points to a corresponding base in [base](../base/README.md).
- Flux sync manifests in [clusters](../clusters/README.md) should target one overlay per environment.

## Example (build an overlay locally)

```bash
kubectl kustomize overlays/dev/learn-go
```

## Notes

- Keep environment-specific values and patches here, not in base.
- Add new app overlays in dev/stg/prod to keep environments consistent.
