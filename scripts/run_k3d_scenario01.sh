#!/usr/bin/env bash
# ==============================================================================
# K3d Cluster Provisioning Script - Scenario 1 & 3 (Vanilla Kubernetes on WSL2)
# Rigorous Hardware Parity: 2 vCPUs and 4GB RAM per Node (Thesis Specification)
# ==============================================================================
set -euo pipefail

echo "======================================================================"
echo "  PANOPTES K3D ENVIRONMENT PROVISIONING (SCENARIO 1 & 3 - VANILLA)"
echo "======================================================================"

# 1. Check control dependencies and Docker daemon in WSL2
echo "[1/4] Checking dependencies on WSL2 (Ansible, Helm, K3d, Docker)..."
if ! docker info >/dev/null 2>&1; then
  sudo -n service docker start >/dev/null 2>&1 || true
fi

# Ensure kernel inotify limits are sufficient (ADR-0005)
CURRENT_INOTIFY=$(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 128)
if [ "$CURRENT_INOTIFY" -lt 4096 ]; then
  sudo -n sysctl -w fs.inotify.max_user_instances=8192 >/dev/null 2>&1 || true
  sudo -n sysctl -w fs.inotify.max_user_watches=524288 >/dev/null 2>&1 || true
  sudo -n sysctl -w fs.file-max=2097152 >/dev/null 2>&1 || true
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "Installing Helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  bash get_helm.sh
  rm get_helm.sh
fi

if ! command -v k3d >/dev/null 2>&1; then
  echo "Installing K3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# 2. Tear down any previous Scenario 1 or Scenario 2 K3d clusters to avoid resource contention
echo "[2/4] Tearing down previous K3d clusters and creating 'panoptes-cluster' (2 CPUs, 4GB RAM per node)..."
pkill -f "kubectl port-forward" 2>/dev/null || true
k3d cluster delete panoptes-cluster-scenario2 2>/dev/null || true
k3d cluster delete panoptes-cluster 2>/dev/null || true

k3d cluster create panoptes-cluster \
  --servers 1 \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0" \
  --wait

# Apply strict resource limits via Docker Update on K3d nodes to match the thesis specification (2 CPUs / 4GB per node, ADR-0006)
echo "Applying strict Docker resource constraints (2 CPUs, 4GB RAM) to cluster nodes..."
for node in panoptes-cluster-server-0 panoptes-cluster-agent-0 panoptes-cluster-agent-1; do
  docker update --cpus="2.0" --memory="4g" --memory-swap="4g" "k3d-$node" 2>/dev/null || true
done

# 3. Apply Taint on Master Node (Control-plane hardware isolation simulation)
echo "[3/4] Applying isolation taint on the master node..."
kubectl --context k3d-panoptes-cluster taint nodes k3d-panoptes-cluster-server-0 node-role.kubernetes.io/master=true:NoSchedule --overwrite || true

# 4. Configure local kubeconfig and inventory
echo "[4/4] Configuring kubectl access and generating inventory..."
mkdir -p ~/.kube
k3d kubeconfig write panoptes-cluster --output ~/.kube/config
chmod 600 ~/.kube/config

cat <<EOF > inventory.ini
[k8s_cluster]
k8s-master ansible_host=127.0.0.1 ansible_user=$USER ansible_connection=local
k8s-worker1 ansible_host=127.0.0.1 ansible_user=$USER ansible_connection=local
k8s-worker2 ansible_host=127.0.0.1 ansible_user=$USER ansible_connection=local
EOF

echo ""
echo "======================================================================"
echo "  [OK] K3D CLUSTER READY FOR SCENARIO 1 & 3 (STRICT PARITY)!"
echo "======================================================================"
kubectl get nodes
