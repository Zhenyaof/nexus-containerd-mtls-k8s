#!/usr/bin/env bash
set -euo pipefail

REGISTRY_HOST="${REGISTRY_HOST:-192.168.198.140:8443}"
IMAGE="${IMAGE:-${REGISTRY_HOST}/nginx:1.28-alpine}"

echo "Authenticating sudo access..."
sudo -v

read -rsp "Nexus registry password: " NEXUS_PASS
echo
trap 'unset NEXUS_PASS' EXIT

sudo ctr -n k8s.io images pull \
  --hosts-dir /etc/containerd/certs.d \
  --user "admin:${NEXUS_PASS}" \
  "$IMAGE"

unset NEXUS_PASS
trap - EXIT

echo "Registry pull succeeded: $IMAGE"
