#!/bin/bash -e

my_tmp=$(mktemp -d)
cd $my_tmp

# k9s
curl -fL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz -o k9s.tar.gz
tar xzvf k9s.tar.gz
mv k9s /usr/local/bin

# bashrc

cat > /etc/bash.bashrc.local <<EOF
if [ -z "$KUBECONFIG" ]; then
    if [ -e /etc/rancher/rke2 ]; then
        export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    else
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    fi
fi
if [ -d /var/lib/rancher/rke2/bin ]; then
    export PATH="${PATH}:/var/lib/rancher/rke2/bin"
fi
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

echo "source /etc/bash.bashrc.local" >> /root/.bashrc

rm -rf $my_tmp
