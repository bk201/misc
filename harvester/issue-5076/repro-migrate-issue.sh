#!/bin/bash -ex
# repro https://github.com/harvester/harvester/issues/5076 
NEW_KUBEVIRT_OPERATOR_IMAGE="registry.suse.com/suse/sles/15.5/virt-operator:1.1.0-150500.8.6.1"
NEW_KUBEVIRT_VERSION="1.1.0-150500.8.6.1"
TEST_VM_NAME=ubuntu-0
TEST_VM_NAMESPACE=harvester-public

create_rbac() {

    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
  name: kubevirt-operator-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubevirt-operator
  namespace: harvester-system
EOF
  
}


patch_virt_operator_deployment() {
    local patch_file=$(mktemp)
    cat > $patch_file <<EOF
spec:
  template:
    spec:
      containers:
      - env:
        - name: OPERATOR_IMAGE
          value: $NEW_KUBEVIRT_OPERATOR_IMAGE
        image: $NEW_KUBEVIRT_OPERATOR_IMAGE
        name: virt-operator
EOF

    kubectl patch deployment virt-operator --namespace harvester-system --patch-file $patch_file --type merge
    rm $patch_file
}


wait_kubevirt() {
  # Wait for kubevirt to be upgraded
  namespace=$1
  name=$2
  version=$3

  echo "Waiting for KubeVirt to upgraded to $version..."
  set +x
  while [ true ]; do
    kubevirt=$(kubectl get kubevirts.kubevirt.io $name -n $namespace -o yaml)

    current_phase=$(echo "$kubevirt" | yq e '.status.phase' -)
    current_target_version=$(echo "$kubevirt" | yq e '.status.observedKubeVirtVersion' -)

    if [ "$current_target_version" = "$version" ]; then
      if [ "$current_phase" = "Deployed" ]; then
        break
      fi
    fi

    echo "KubeVirt current version: $current_target_version, target version: $version"
    sleep 5
  done
  set -x
}


migrate_vm() {
    cat <<EOF | kubectl create -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachineInstanceMigration
metadata:
  generateName: $TEST_VM_NAME
  namespace: $TEST_VM_NAMESPACE
spec:
  vmiName: $TEST_VM_NAME
EOF
}

upgrade_kubevirt() {
    create_rbac
    patch_virt_operator_deployment
    wait_kubevirt harvester-system kubevirt $NEW_KUBEVIRT_VERSION
}

upgrade_kubevirt
migrate_vm
