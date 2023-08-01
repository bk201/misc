#!/bin/bash -ex

zypper in -y apparmor-parser iptables wget open-iscsi

curl -fL https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz -o /tmp/k9s.tar.gz && cd /tmp && tar xzvf k9s.tar.gz && cp k9s /usr/local/bin/ && chmod +x /usr/local/bin/k9s

cat > /etc/bash.bashrc.local <<EOF
if [ -z "$KUBECONFIG" ]; then
    if [ -e /etc/rancher/rke2/rke2.yaml ]; then
        export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
    else
        export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
    fi
fi
export PATH="${PATH}:/var/lib/rancher/rke2/bin"
if [ -z "$CONTAINER_RUNTIME_ENDPOINT" ]; then
    export CONTAINER_RUNTIME_ENDPOINT=unix:///var/run/k3s/containerd/containerd.sock
fi
if [ -z "$IMAGE_SERVICE_ENDPOINT" ]; then
    export IMAGE_SERVICE_ENDPOINT=unix:///var/run/k3s/containerd/containerd.sock
fi
# For ctr
if [ -z "$CONTAINERD_ADDRESS" ]; then
    export CONTAINERD_ADDRESS=/run/k3s/containerd/containerd.sock
fi
EOF

mkdir -p /etc/rancher/rke2/config.yaml.d/
cat > /etc/rancher/rke2/config.yaml.d/99-vagrant-rancherd.yaml << EOF
cni: multus,canal
disable: rke2-ingress-nginx
EOF

mkdir -p /etc/rancher/rancherd
cat > /etc/rancher/rancherd/config.yaml << EOF
role: cluster-init
token: somethingrandom
kubernetesVersion: v1.24.16+rke2r1
rancherVersion: v2.6.11
rancherValues:
  noDefaultAdmin: false
  bootstrapPassword: admin
  features: multi-cluster-management=yes,multi-cluster-management-agent=false
  global:
    cattle:
      psp:
        enabled: false
EOF

curl -fL https://raw.githubusercontent.com/rancher/rancherd/master/install.sh | sh -

