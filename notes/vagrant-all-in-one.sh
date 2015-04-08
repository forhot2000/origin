#!/bin/bash

cd $GOPATH/src/github.com/openshift/origin

make clean build

sudo systemctl start openshift

echo 'wait web service enabled...'
sleep 10

# open https://localhost:8443/console/

sudo chmod +r /openshift.local.certificates/admin/.kubeconfig
sudo chmod +r /openshift.local.certificates/openshift-registry/.kubeconfig
sudo chmod +r /openshift.local.certificates/openshift-router/.kubeconfig

openshift ex policy add-role-to-user view test-admin

# refresh https://localhost:8443/console/, you can see default project

openshift ex registry --create --credentials="/openshift.local.certificates/openshift-registry/.kubeconfig"

# goto pods view, a docker-registry-1-30qpc pod is created here, and it is pending by pull the image

openshift ex router --create --credentials="/openshift.local.certificates/openshift-router/.kubeconfig"

# goto pods view, a router-1-877md pod is created here, and it is pending by pull the image


cd $GOPATH/src/github.com/openshift/origin/examples/sample-app
openshift ex new-project test --display-name="OpenShift 3 Sample" --description="This is an example project to demonstrate OpenShift v3" --admin=test-admin
osc process -n test -f application-template-stibuild.json | osc create -n test -f -


# clean
echo "Killing openshift all-in-one server"
sudo systemctl stop openshift
echo "Cleaning up openshift etcd content"
sudo rm -rf /openshift.local.etcd
echo "Cleaning up openshift etcd volumes"
sudo rm -rf /openshift.local.volumes
echo "Stopping all k8s docker containers on host"
docker ps | awk '{ print $NF " " $1 }' | grep ^k8s_ | awk '{print $2}' |  xargs -l -r docker stop
echo "Remove all k8s docker containers on host"
docker ps -a | awk '{ print $NF " " $1 }' | grep ^k8s_ | awk '{print $2}' |  xargs -l -r docker rm




## debug

sudo journalctl -f -u openshift


