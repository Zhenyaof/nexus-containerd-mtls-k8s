# Nexus Containerd mTLS Integration with Kubernetes

Configure containerd to securely pull container images from a private Nexus Repository Docker registry over HTTPS using mutual TLS (mTLS), then run the image in Kubernetes.

## Architecture

- **Nexus Repository:** Hosts the private Docker image.
- **Nginx reverse proxy:** Terminates HTTPS, validates client certificates, and forwards registry requests to Nexus.
- **Containerd:** Verifies the registry's TLS certificate and presents its client certificate.
- **Kubernetes:** Runs a pod using an image stored in Nexus.

## Tested Environment

- Ubuntu 24.04
- Kubernetes v1.37.0
- containerd 2.2.1
- Nexus Repository OSS 3.96.3
- Nginx 1.28
- Registry: `192.168.198.140:8443`
- Test image: `nginx:1.28-alpine`

These are the versions used in the lab, not universal requirements.

## Repository Structure

```text
.
├── .github/workflows/validate.yml
├── containerd/
│   ├── config.toml.example
│   └── hosts.toml.example
├── docs/
│   ├── architecture.mmd
│   └── troubleshooting.md
├── kubernetes/
│   └── pod.yaml
├── scripts/
│   ├── check-prerequisites.sh
│   └── test-registry.sh
├── .gitignore
└── README.md
```

## Prerequisites

- A working Kubernetes cluster using containerd.
- A Nexus Docker hosted repository.
- An HTTPS reverse proxy configured for client certificate verification.
- A trusted CA certificate, client certificate, and matching private key.
- Registry credentials with permission to pull images.
- Network connectivity from Kubernetes nodes to the registry.

## 1. Install Certificates

On every Kubernetes node that needs to pull images, create the registry-specific certificate directory:

```bash
sudo mkdir -p /etc/containerd/certs.d/192.168.198.140:8443
```

Install these files securely:

```text
/etc/containerd/certs.d/192.168.198.140:8443/ca.crt
/etc/containerd/certs.d/192.168.198.140:8443/client.crt
/etc/containerd/certs.d/192.168.198.140:8443/client.key
```

The CA certificate validates the registry's server certificate. The client certificate and private key authenticate the node to the registry's HTTPS endpoint.

Never copy the CA private key to Kubernetes nodes or commit private keys to Git.

## 2. Configure Containerd

Review the examples in the `containerd/` directory and merge the registry configuration into the existing containerd configuration.

Configure the registry certificate directory as:

```text
/etc/containerd/certs.d
```

Install the registry-specific `hosts.toml` and ensure its certificate paths match the files installed on the node.

If the main containerd configuration changes, restart containerd and verify that Kubernetes nodes return to `Ready`.

## 3. Test the Registry Pull

Pull the test image using containerd:

```bash
read -rsp "Nexus password: " NEXUS_PASS
echo

sudo ctr -n k8s.io images pull \
  --hosts-dir /etc/containerd/certs.d \
  --user "admin:$NEXUS_PASS" \
  192.168.198.140:8443/nginx:1.28-alpine

unset NEXUS_PASS
```

Use a dedicated pull-only registry account instead of the administrator account for regular use.

## 4. Create Kubernetes Registry Credentials

When the registry requires username/password authentication, create a Kubernetes image pull secret:

```bash
read -rsp "Registry password: " REGISTRY_PASS
echo

kubectl create secret docker-registry nexus-registry \
  --docker-server=192.168.198.140:8443 \
  --docker-username=admin \
  --docker-password="$REGISTRY_PASS"

unset REGISTRY_PASS
```

If the secret already exists, update it using a secure workflow rather than creating it again.

mTLS and registry credentials serve different purposes: the client certificate authenticates the HTTPS client, while the Kubernetes secret supplies registry credentials.

## 5. Deploy the Test Pod

Review `kubernetes/pod.yaml` and replace the example registry address if necessary.

```bash
kubectl apply -f kubernetes/pod.yaml
kubectl get pods -o wide
kubectl describe pod nexus-nginx
```

Verify NGINX from inside the pod:

```bash
kubectl exec nexus-nginx -- wget -qO- http://localhost
```

The expected output contains:

```text
Welcome to nginx!
```

## Verification Results

The lab successfully demonstrated:

- Containerd pulled `nginx:1.28-alpine` from Nexus using mTLS.
- Kubernetes ran a pod using the Nexus-tagged image.
- NGINX returned its welcome page from inside the pod.

**Important:** The pod used an image already cached on the node. A separate clean-cache test is needed to prove Kubernetes can pull the image from Nexus during pod startup.

## Troubleshooting

See [`docs/troubleshooting.md`](docs/troubleshooting.md) for common certificate, authentication, containerd, and Kubernetes issues.

## Security

- Never commit passwords, private keys, or real environment-specific secrets.
- Restrict permissions on client private keys.
- Use least-privilege registry credentials.
- Protect Kubernetes Secrets and consider an external secrets manager for production.
- Use trusted certificates and validate the registry's server identity.
- Replace the lab IP address and paths with your own environment's values.

## License

Add a license file before distributing or reusing this project.
