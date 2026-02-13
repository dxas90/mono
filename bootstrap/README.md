# 🚀 Bootstrap Infrastructure

This folder contains the minimal manifests required to bootstrap a Kubernetes cluster with Flux CD and SOPS age keys.

## Prerequisites

- `kubectl` with access to the target cluster
- `flux` CLI (for validation and status checks)
- `sops` and `age` (to decrypt and apply sealed secrets)

## Quick Start

1. Apply the bootstrap Kustomization from repo root:

```bash
kubectl apply --kustomize bootstrap
```

1. Apply the Flux sync manifests for your cluster profile (example for kind + dev):

```bash
kubectl apply -f clusters/kind/gotk-sync.yaml -f clusters/kind/dev/gotk-sync.yaml
```

1. Decrypt and apply the SOPS age secret used by Flux:

```bash
sops exec-file "bootstrap/sops-age.sops.yaml" \
 "kubectl --namespace flux-system apply --server-side --filename {}"
```

## Notes

- Keep `sops-age.sops.yaml` encrypted at rest; only apply it through `sops`.
- Run `flux check` and `flux get kustomizations --all-namespaces` to verify reconciliation.
