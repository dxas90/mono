# Base

Base app resources used by overlays. These kustomizations are shared across environments and should stay environment-agnostic.

## Structure

```text
base/
├── learn-go/
├── learn-python/
├── learn-rust/
├── mesh/
└── ui/
```

Each app folder typically contains:

- Flux resources and kustomize definitions
- Labels shared across environments

## How it fits

- Overlays in [overlays](../overlays/README.md) compose these bases with environment-specific values.
- Flux sync manifests in [clusters](../clusters/README.md) point to overlay paths, not base paths.

## Notes

- Keep secrets out of base unless they are encrypted with SOPS.
- Prefer app-specific overrides in overlays rather than patching base directly.
