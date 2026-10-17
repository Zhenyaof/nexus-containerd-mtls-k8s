#!/usr/bin/env bash
set -euo pipefail

REGISTRY_HOST="${REGISTRY_HOST:-192.168.198.140:8443}"
CERT_DIR="/etc/containerd/certs.d/${REGISTRY_HOST}"

echo "Checking required commands..."
for cmd in kubectl ctr openssl; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK: $cmd"
  else
    echo "MISSING: $cmd"
  fi
done

echo
echo "Checking containerd service..."
if systemctl is-active --quiet containerd; then
  echo "OK: containerd is running"
else
  echo "WARNING: containerd is not running or systemd is unavailable"
fi

echo
echo "Checking registry certificates in $CERT_DIR..."
for file in ca.crt client.crt client.key; do
  if sudo test -r "$CERT_DIR/$file"; then
    echo "OK: $file is readable by root"
  else
    echo "MISSING or unreadable: $CERT_DIR/$file"
  fi
done

echo
echo "Prerequisite checks completed. Review any warnings above."
