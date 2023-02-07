#!/bin/bash -eux

BUNDLE_ARCHIVE=$1
BUNDLE_ARCHIVE_ABS=$(readlink -f $BUNDLE_ARCHIVE)
BUNDLE_ARCHIVE_ROOT=$(dirname $BUNDLE_ARCHIVE_ABS)
SBK_BIN="/home/kiefer/codes/rancher/support-bundle-kit/bin/support-bundle-kit"

BUNDLE_NAME=$(basename -s .zip $BUNDLE_ARCHIVE)
SIM_HOME="$BUNDLE_ARCHIVE_ROOT/${BUNDLE_NAME}-sim"

extract_bundle()
{
  unzip $BUNDLE_ARCHIVE_ABS -d $BUNDLE_ARCHIVE_ROOT
  cd $BUNDLE_ARCHIVE_ROOT/$BUNDLE_NAME/nodes
  ls *.zip | xargs -I {} unzip {}
}

if [ ! -d $BUNDLE_NAME ]; then
  extract_bundle
fi

cd $BUNDLE_ARCHIVE_ROOT/$BUNDLE_NAME

mkdir -p $SIM_HOME
SIM_ARGS="--reset"
if [ -e $SIM_HOME/admin.kubeconfig ]; then
  SIM_ARGS="--skip-load"
fi

echo "export KUBECONFIG=$SIM_HOME/admin.kubeconfig"


read -p "Run simulator?(y/n)" -s -s yes

if [ "${yes}" == "y" ]; then
  echo "export KUBECONFIG=$SIM_HOME/admin.kubeconfig"
  $SBK_BIN simulator --sim-home $SIM_HOME $SIM_ARGS
else
  echo "You can run simulator with \"$SBK_BIN simulator --sim-home $SIM_HOME $SIM_ARGS\""
fi

