#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "--> Cleanup VMs"
sudo virsh list --all | (grep -E "(admin|(master|worker)_[0-9]+)" || :) | awk '{print $2}' | \
  xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh destroy {}; sudo virsh undefine {}'

echo "--> Cleanup Networks"
sudo virsh net-list --all | (grep "caasp-dev-net" || :) | awk '{print $1}' | \
  xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh net-destroy {}; sudo virsh net-undefine {}'

echo "--> Cleanup Volumes"
pools="$(sudo virsh pool-list --all | sed 1,2d | awk '{print $1}')"
for pool in $pools; do
sudo virsh vol-list --pool "$pool" | \
  (grep -E "(admin(_cloud_init)?|(master|worker)(_cloud_init)?_[0-9]+)|additional-worker-volume" || :) | \
  awk '{print $1}' | xargs --no-run-if-empty -n1 -I{} sh -c "sudo virsh vol-delete --pool '$pool' {}"
done

echo "--> Cleanup Terraform states from caasp-kvm"
pushd $DIR/.. > /dev/null
rm -f cluster.tf terraform.tfstate*
popd  > /dev/null

echo "Creanup Done"
