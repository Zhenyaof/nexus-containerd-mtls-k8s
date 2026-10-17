# Troubleshooting

## TLS certificate verification

Check the certificate files:

    sudo ls -l /etc/containerd/certs.d/192.168.198.140:8443/

Test mTLS with the installed certificates:

    sudo curl -sS -i \
      --cacert /etc/containerd/certs.d/192.168.198.140:8443/ca.crt \
      --cert /etc/containerd/certs.d/192.168.198.140:8443/client.crt \
      --key /etc/containerd/certs.d/192.168.198.140:8443/client.key \
      https://192.168.198.140:8443/v2/

An HTTP 401 response can mean TLS succeeded but registry credentials are required.

## Missing client certificate

Nginx may return `400 No required SSL certificate was sent` when a request lacks a client certificate. Configure the client certificate and key in containerd's `hosts.toml` or pass them explicitly to curl.

## Registry authentication failure

A `401 Unauthorized` response indicates that registry authorization is still required. Check the Nexus username, password, and repository permissions.

If Nexus returns `429 Too many authentication attempts`, stop retrying with incorrect or placeholder credentials. Verify the credentials before trying again.

## containerd registry configuration

The registry-specific configuration belongs at:

    /etc/containerd/certs.d/192.168.198.140:8443/hosts.toml

Use the parent directory with `ctr`:

    sudo ctr -n k8s.io images pull \
      --hosts-dir /etc/containerd/certs.d \
      192.168.198.140:8443/nginx:1.28-alpine

Supply valid credentials when required. For Kubernetes CRI, configure the appropriate `config_path` in containerd's `config.toml`.

## Kubernetes image pull failure

Inspect pod details and events:

    kubectl describe pod nexus-nginx
    kubectl get events --sort-by=.lastTimestamp

Check the image name, registry endpoint, containerd configuration, and image pull secret.

A successful `ctr` pull does not independently prove a fresh kubelet pull. The existing pod used an image already present on the node.

## Security

Do not use `curl -k` as a production workaround because it disables server certificate verification. Prefer a dedicated Nexus pull-only account instead of administrator credentials.
