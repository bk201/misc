#!/bin/bash -ex


NODE=$1

MACHINE=$(kubectl get node $NODE -o yaml | yq -e e '.metadata.annotations."cluster.x-k8s.io/machine"' -)

data=$(kubectl get secret -n fleet-local $MACHINE-machine-plan -o yaml | yq -e e '.metadata.annotations."rke.cattle.io/pre-drain"' -)

echo harvester.cattle.io/pre-hook: "'"$data"'"

kubectl annotate secret -n fleet-local $MACHINE-machine-plan harvesterhci.io/pre-hook="$data"


