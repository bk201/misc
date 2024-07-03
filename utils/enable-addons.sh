#!/bin/bash -e

addons=(vm-import-controller harvester-seeder pcidevices-controller rancher-logging rancher-monitoring)

wait_addon() {
    local addon=$1
    local ns=$2

    retry=0
    while [ true ]; do
        if [ $retry -eq 60 ]; then
            echo "timeout when waiting $addon to be deployed."
            exit 1
        fi

        status=$(kubectl get -n $ns addons.harvesterhci.io $addon -o yaml | yq .status.status)

        if [ -z $status ]; then
            echo "fail to get status of the addon $addon"
            exit 1
        fi

        if [ "$status" = "AddonDeploySuccessful" ]; then
            echo "addon $addon is deployed."
            return
        fi

        echo "wait for 5 seconds to retry..."
        sleep 5
        retry=$((retry+1))
    done
}

enable_addon() {
    local addon=$1
    local tmp_yaml=$(mktemp --suffix=.yaml)

    echo "Enabling $addon..."

    case $addon in
        pcidevices-controller | harvester-seeder | vm-import-controller)
            ns=harvester-system
            ;;
        rancher-logging)
            ns=cattle-logging-system
            ;;
        rancher-monitoring)
            ns=cattle-monitoring-system
            ;;
    esac

cat > $tmp_yaml <<EOF
apiVersion: harvesterhci.io/v1beta1
kind: Addon
metadata:
  name: $addon
  namespace: $ns
spec:
  enabled: true
EOF

cat $tmp_yaml

    kubectl patch -n $ns addons.harvesterhci.io $addon --patch-file $tmp_yaml --type merge
    rm -f $tmp_yaml

    wait_addon $addon $ns
}

for addon in ${addons[@]}; do
  enable_addon $addon
done
