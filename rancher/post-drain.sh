#!/bin/bash -exu


NODE=$1

MACHINE=$(kubectl get node $NODE -o yaml | yq -e e '.metadata.annotations."cluster.x-k8s.io/machine"' -)

data=$(kubectl get secret -n fleet-local $MACHINE-machine-plan -o yaml | yq -e e '.metadata.annotations."rke.cattle.io/post-drain"' -)

echo harvester.cattle.io/post-hook: "'"$data"'"

kubectl annotate secret -n fleet-local $MACHINE-machine-plan harvesterhci.io/post-hook="$data"

