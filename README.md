# Kustomize Plugin Usage Guide

## Overview

Community/vendor Helm charts often don't expose every field you need (env vars, sidecar containers, resource tweaks, labels) via values.yaml. Rather than forking the chart, this plugin lets you patch the rendered output directly, targeting any resource by kind, name, namespace, or label — without touching the chart source.

It plugs into Helm's standard --post-renderer hook (Helm 4's plugin-based mechanism), so it works uniformly across helm template, helm install, helm upgrade, and helm diff — giving you a single patch file that governs preview, diff-against-live-state, and actual deployment.

## Prerequisites
- Helm v4.0+

- kubectl 

## Installation
```
helm plugin install https://github.com/ashishkumar256/helm-kustomize
```

## Validate
```
helm plugin list
```
```
NAME            VERSION TYPE            APIVERSION      PROVENANCE      SOURCE
kustomize       0.1.0   postrenderer/v1 v1              unknown         unknown
```

## Create a Patch File
Create a patch.yaml file with your desired modifications. The patch uses JSON Patch (RFC 6902) format:
```
cat <<'EOF' > patch.yaml
- target:
    kind: Deployment
    name: metrics-server
  patch: |-
    - op: add
      path: /spec/template/spec/containers/0/env
      value:
        - name: LOG_LEVEL
          value: "debug"
EOF
```


**Patch Operations-**

Operation	Description	Example

`add`	Add a new field	Add environment variable

`replace`	Replace existing field	Change image tag

`remove`	Remove a field	Remove a label


# Usage Examples

## Basic Usage with Helm
```
helm template RELEASE_NAME CHART_NAME \
  --post-renderer kustomize \
  --post-renderer-args patch.yaml \
  -s TEMPLATE_FILE
```

## Specific Example: Metrics Server
```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

helm template metrics-server metrics-server/metrics-server \
  --post-renderer kustomize \
  --post-renderer-args patch.yaml \
  -s templates/deployment.yaml
```

## Verify 
```
---
# Source: metrics-server/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/instance: metrics-server
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: metrics-server
    app.kubernetes.io/version: 0.8.1
    helm.sh/chart: metrics-server-3.13.1
  name: metrics-server
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: metrics-server
      app.kubernetes.io/name: metrics-server
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: metrics-server
        app.kubernetes.io/name: metrics-server
    spec:
      containers:
      - env:
        - name: LOG_LEVEL
          value: debug

```

## Compatibility with other plugin like helm-diff
Let's update `LOG_LEVEL` value to `info` -
```
helm diff --context 2 upgrade --install metrics-server -n monitoring metrics-server/metrics-server \
  --post-renderer kustomize \
  --post-renderer-args patch.yaml
monitoring, metrics-server, Deployment (apps) has changed:
...
          env:
          - name: LOG_LEVEL
-           value: debug
+           value: info
          image: registry.k8s.io/metrics-server/metrics-server:v0.8.1
          imagePullPolicy: IfNotPresent
...
```

## How it works
```
helm template/install/upgrade
        │
        ▼
  chart renders manifests (stdout)
        │
        ▼
  Helm pipes manifests → patch.sh (stdin)
        │
        ▼
  patch.sh wraps them in a temp kustomization.yaml alongside your patch.yaml
        │
        ▼
  kustomize build applies the patches
        │
        ▼
  patched manifests → stdout → Helm → cluster / --dry-run output
  ```

## Components
- `plugin.yaml`	Helm 4 plugin manifest — declares type: postrenderer/v1, subprocess runtime, entrypoint
- `patch.sh`	Wraps stdin manifests + your patch file into a kustomize job, runs kustomize build
- `patch.yaml` (user-supplied)	List of {target, patch} objects — your actual JSON6902 edits

## Troubleshooting
```
# Check plugin directory
ls -la ~/.local/share/helm/plugins/helm-kustomize/

# Reinstall plugin
helm plugin uninstall kustomize
helm plugin install https://github.com/ashishkumar256/helm-kustomize
```

## Docs
- Issues:  [GitHub Issues](https://github.com/ashishkumar256/helm-kustomize/issues)

- Documentation: [Helm Postrenderer Plugin Docs](https://helm.sh/docs/plugins/developer/tutorial-postrenderer-plugin)
  
- Kubectl: [Kubectl Docs](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_kustomize)

- Kustomize: [Kustomize Documentation](https://kustomize.io/)


## Support
Made with ❤️ by the Kubernetes Community

