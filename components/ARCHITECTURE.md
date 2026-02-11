# GitLab CI/CD Components Architecture

## Component-Based Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Catalog                            │
│  (Discoverable, Versioned, Published Components)            │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Browse & Include
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              Component Project Repository                   │
│                 (your-group/components)                     │
├─────────────────────────────────────────────────────────────┤
│  templates/                                                 │
│    ├── python-test.yml           (Test Component)           │
│    ├── node-test.yml             (Test Component)           │
│    ├── go-test.yml               (Test Component)           │
│    ├── buildah-containerize/     (Build Component)          │
│    │   └── template.yml                                     │
│    ├── image-promote/            (Promote Component)        │
│    │   └── template.yml                                     │
│    └── k8s-deploy/               (Deploy Component)         │
│        └── template.yml                                     │
│                                                             │
│  .gitlab-ci.yml    (Test & Release Pipeline)                │
│  README.md         (Documentation)                          │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Include
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                  Application Projects                       │
│                                                             │
│  Project 1 (.gitlab-ci.yml)                                 │
│  ├── include:                                               │
│  │   - component: .../python-test@1.0.0                     │
│  │   - component: .../buildah-containerize@1.0.0            │
│  └── stages: [test, build]                                  │
│                                                             │
│  Project 2 (.gitlab-ci.yml)                                 │
│  ├── include:                                               │
│  │   - component: .../go-test@1.0.0                         │
│  │   - component: .../buildah-containerize@1.0.0            │
│  └── stages: [test, build, deploy]                          │
└─────────────────────────────────────────────────────────────┘
```

## Component Lifecycle

```text
┌──────────────┐
│   Develop    │  Create/Update component in templates/
└──────┬───────┘
       │
       ↓
┌──────────────┐
│     Test     │  Run .gitlab-ci.yml to test component
└──────┬───────┘
       │
       ↓
┌──────────────┐
│    Commit    │  Commit to main branch
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Tag        │  Create semantic version tag (e.g., 1.0.0)
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Release    │  Pipeline automatically creates release
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Publish    │  Component appears in CI/CD Catalog
└──────┬───────┘
       │
       ↓
┌──────────────┐
│     Use      │  Projects can include @version
└──────────────┘
```

## Data Flow: Build Pipeline Example

```text
Application Project (.gitlab-ci.yml)
    │
    └── include: python-test@1.0.0
    │       ↓
    │   [Python Test Job]
    │       │
    │       ├── pip install
    │       ├── pytest
    │       └── ✓ Tests pass
    │
    └── include: buildah-containerize@1.0.0
    │       ↓
    │   [Containerize Job]
    │       │
    │       ├── Auto-detect Dockerfile
    │       ├── Build image
    │       ├── Tag: branch-feature-name
    │       ├── Push to registry
    │       └── Output: IMAGE_TAG=...
    │
    └── include: k8s-deploy@1.0.0
            ↓
        [Deploy Job]
            │
            ├── Read IMAGE_TAG
            ├── Determine environment
            │   └── Feature branch → Ephemeral namespace
            ├── kubectl apply
            └── ✓ Deployed to feature-namespace
```

## Input/Output Flow

```text
Component Definition (template.yml)
┌────────────────────────────────────┐
│ spec:                              │
│   inputs:                          │
│     stage:                         │
│       default: test                │
│     job_name:                      │
│       default: "my-job"            │
│     custom_value:                  │
│       description: "..."           │
└────────────────────────────────────┘
         │ Interpolation
         ↓
┌────────────────────────────────────┐
│ "$[[ inputs.job_name ]]":          │
│   stage: $[[ inputs.stage ]]       │
│   script:                          │
│     - use $[[ inputs.custom_value ]]│
│   artifacts:                       │
│     reports:                       │
│       dotenv: output.env           │
└────────────────────────────────────┘
         │ Generated
         ↓
Application Pipeline
┌────────────────────────────────────┐
│ my-custom-job:                     │
│   stage: build                     │
│   script:                          │
│     - use "my-value"               │
│   artifacts:                       │
│     OUTPUT_VAR=value               │
└────────────────────────────────────┘
```

## Monorepo Architecture

```text
Monorepo Project
├── apps/
│   ├── api/           (Python)
│   ├── frontend/      (Node.js)
│   └── worker/        (Go)
│
└── .gitlab-ci.yml
    │
    ├── Test Stage
    │   ├── [python-test] → apps/api
    │   ├── [node-test]   → apps/frontend
    │   └── [go-test]     → apps/worker
    │
    ├── Build Stage
    │   ├── [buildah] → api:latest
    │   ├── [buildah] → frontend:latest
    │   └── [buildah] → worker:latest
    │
    └── Deploy Stage
        ├── [k8s-deploy] → Ephemeral (branches)
        ├── [k8s-deploy] → Staging (main)
        └── [k8s-deploy] → Production (tags)
```

## Version Management

```text
Component Releases
├── 1.0.0     (Stable)
│   └── Projects using @1.0.0 or @1.0 or @1
│
├── 1.1.0     (New features)
│   └── Projects using @1.1 or @1
│
├── 1.1.1     (Bug fix)
│   └── Projects using @1.1 or @1
│
├── 2.0.0     (Breaking changes)
│   └── Projects using @2 or @~latest
│
└── main      (Development)
    └── Testing only: @$CI_COMMIT_SHA

Version Selection Priority:
1. Exact version: @1.0.0
2. Partial: @1.0 → latest 1.0.x
3. Major: @1 → latest 1.x.x
4. Latest: @~latest → latest release
5. Commit: @abc123 → specific commit
6. Branch: @main → latest on branch
```

## Security Model

```text
┌──────────────────────────────────────┐
│     Component Project                │
│  ┌────────────────────────────────┐  │
│  │  Protected Branches:           │  │
│  │  - main (no direct push)       │  │
│  │  - release-* (no direct push)  │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  Required Approvals:           │  │
│  │  - 2 maintainers for MRs       │  │
│  │  - Signed commits required     │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
              │
              │ Access Control
              ↓
┌──────────────────────────────────────┐
│     Using Projects                   │
│  ┌────────────────────────────────┐  │
│  │  Minimum Role: Reporter        │  │
│  │  Can: Include components       │  │
│  │  Cannot: Modify components     │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  Best Practices:               │  │
│  │  - Pin to versions             │  │
│  │  - Review component code       │  │
│  │  - Use minimal permissions     │  │
│  │  - Audit usage                 │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

## Comparison: Old vs New

### Old Template System

```text
Project
├── .gitlab-ci.yml
│   ├── include: local .gitlab-ci-common.yml
│   └── extends: .containerize
│
└── Limitations:
    ├── No versioning
    ├── Manual sync across projects
    ├── Hard to discover
    └── Difficult to test in isolation
```

### New Component System

```text
Component Project              Using Projects
├── templates/                     ├── .gitlab-ci.yml
│   └── component@1.0.0  ──────>   │   └── include: component@1.0.0
│                                  │
└── Benefits:                      └── Benefits:
    ├── Semantic versioning            ├── Pin to stable version
    ├── Central updates                ├── Auto-discover in catalog
    ├── Discoverable in catalog        ├── Clear documentation
    ├── Tested independently           ├── Reliable behavior
    └── Shared across org              └── Easy to update
```

## Integration Points

```text
                    GitLab Instance
┌────────────────────────────────────────────────────┐
│                                                    │
│  ┌──────────────┐      ┌──────────────┐            │
│  │   Projects   │◄────►│  Components  │            │
│  └──────────────┘      └──────────────┘            │
│         │                      │                   │
│         │                      │                   │
│         ↓                      ↓                   │
│  ┌──────────────┐      ┌──────────────┐            │
│  │  Pipelines   │      │   Catalog    │            │
│  └──────────────┘      └──────────────┘            │
│         │                      ↑                   │
│         │                      │                   │
│         ↓                      │                   │
│  ┌──────────────┐      ┌──────────────┐            │
│  │   Registry   │      │   Releases   │            │
│  └──────────────┘      └──────────────┘            │
│         │                      ↑                   │
│         │                      │                   │
│         ↓                      │                   │
│  ┌──────────────────────────────────┐              │
│  │      Kubernetes Cluster          │              │
│  └──────────────────────────────────┘              │
│                                                    │
└────────────────────────────────────────────────────┘
```
