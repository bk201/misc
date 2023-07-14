#!/bin/bash -e

REPO_IMAGE=bk201z/harvester-cluster-repo:v1.2.0-rc3
REPO_HARVESTER_CHART_VERSION=v1.2.0-rc3

cd $(mktemp -d)

upgrade_repo() {
  cat >cluster_repo.yaml <<EOF
spec:
  template:
    spec:
      containers:
        - name: httpd
          image: $REPO_IMAGE
EOF

  kubectl patch deployment harvester-cluster-repo -n cattle-system --patch-file ./cluster_repo.yaml --type merge

  until kubectl -n cattle-system rollout status -w deployment/harvester-cluster-repo; do
    echo "Waiting for harvester-cluster-repo deployment ready..."
    sleep 5
  done
}

upgrade_harvester() {
  echo "Upgrading Harvester"

  cat >harvester-crd.yaml <<EOF
spec:
  version: $REPO_HARVESTER_CHART_VERSION
EOF
  kubectl patch managedcharts.management.cattle.io harvester-crd -n fleet-local --patch-file ./harvester-crd.yaml --type merge

  cat >harvester.yaml <<EOF
apiVersion: management.cattle.io/v3
kind: ManagedChart
metadata:
  name: harvester
  namespace: fleet-local
EOF
  kubectl get managedcharts.management.cattle.io -n fleet-local harvester -o yaml | yq e '{"spec": .spec}' - >>harvester.yaml

  NEW_VERSION=$REPO_HARVESTER_CHART_VERSION yq e '.spec.version = strenv(NEW_VERSION)' harvester.yaml -i

  kubectl apply -f ./harvester.yaml
}

upgrade_repo
upgrade_harvester
