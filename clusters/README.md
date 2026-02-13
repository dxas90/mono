# Clusters

This folder holds cluster-specific Flux sync manifests and environment variables. Each provider or local cluster type has its own directory, with optional dev/stg/prod overlays beneath it.

## Structure

```text
clusters/
├── kind/
│   ├── gotk-sync.yaml
│   ├── dev/
│   │   ├── gotk-sync.yaml
│   │   └── cluster-vars.yaml
│   ├── stg/
│   └── prod/
├── aws/
├── gcp/
└── ...
```

## How it fits

- Flux sync manifests point to the Git repository and the desired kustomize path.
- Cluster variables are used to parameterize overlays.
- Each cluster environment should reference a matching overlay in [overlays/README.md](../overlays/README.md).

## Example (kind + dev)

```bash
kubectl apply -f clusters/kind/gotk-sync.yaml -f clusters/kind/dev/gotk-sync.yaml
```

Related files:

- [clusters/kind/gotk-sync.yaml](kind/gotk-sync.yaml)
- [clusters/kind/dev/gotk-sync.yaml](kind/dev/gotk-sync.yaml)
- [clusters/kind/dev/cluster-vars.yaml](kind/dev/cluster-vars.yaml)

## Notes

- Keep cluster-specific secrets encrypted with SOPS as in [bootstrap/sops-age.sops.yaml](../bootstrap/sops-age.sops.yaml).
- For bootstrap steps, see [bootstrap/README.md](../bootstrap/README.md).
