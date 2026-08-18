helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server --create-namespace -n monitoring --wait metrics-server/metrics-server \
  --set args={--kubelet-insecure-tls} \
  --post-renderer patch \
  --post-renderer-args patch.yaml  
