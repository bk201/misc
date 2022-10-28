#!/bin/bash -e

get_machine_from_node() {
  kubectl get node $1 -o jsonpath='{.metadata.annotations.cluster\.x-k8s\.io/machine}'
}

kubectl get nodes -o yaml | yq e '.items[].metadata.name' | while read -r node_name; do
  machine=$(get_machine_from_node $node_name)
  echo ""
  echo "$node_name ($machine)"
  plan_secret="${machine}-machine-plan"

  annotations=$(kubectl get secret $plan_secret -n fleet-local -o jsonpath='{.metadata.annotations}')

  echo -n "  rke-pre-drain: " && echo $annotations | yq e '."rke.cattle.io/pre-drain"'
  echo -n "  harvester-pre-hook " && echo $annotations | yq e '."harvesterhci.io/pre-hook"'
  echo -n "  rke-post-drain: " && echo $annotations | yq e '."rke.cattle.io/post-drain"'
  echo -n "  harvester-post-hook: " && echo $annotations | yq e '."harvesterhci.io/post-hook"'
done

