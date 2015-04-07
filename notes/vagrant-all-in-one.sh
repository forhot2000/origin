#!/bin/bash

cd $GOPATH/src/github.com/openshift/origin

make clean build

sudo systemctl start openshift

echo 'wait web service enabled...'
sleep 10

# open https://localhost:8443/console/

sudo chmod +r /openshift.local.certificates/admin/.kubeconfig
openshift ex policy add-role-to-user view test-admin

# refresh https://localhost:8443/console/, you can see default project

sudo chmod +r /openshift.local.certificates/openshift-registry/.kubeconfig
openshift ex registry --create --credentials="/openshift.local.certificates/openshift-registry/.kubeconfig"

# goto pods view, a docker-registry-1-30qpc pod is created here, and it is pending by pull the image

sudo chmod +r /openshift.local.certificates/openshift-router/.kubeconfig
openshift ex router --create --credentials="/openshift.local.certificates/openshift-router/.kubeconfig"

# goto pods view, a router-1-877md pod is created here, and it is pending by pull the image


cd $GOPATH/src/github.com/openshift/origin/examples/sample-app
openshift ex new-project test --display-name="OpenShift 3 Sample" --description="This is an example project to demonstrate OpenShift v3" --admin=test-admin
osc process -n test -f application-template-stibuild.json | osc create -n test -f -




## debug

sudo journalctl -f -u openshift


