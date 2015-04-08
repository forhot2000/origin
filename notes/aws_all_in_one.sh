#!/bin/bash

# requirements
sudo apt-get install -y git make gcc

# install docker
wget -qO- https://get.docker.com/ | sh

# allow insecure registry, need restart, it will restart after add user to docker group
echo "DOCKER_OPTS='--insecure-registry=172.30.17.0/24 --selinux-enabled'" | sudo tee --append /etc/default/docker > /dev/null

# allow user to use docker without sudo
# see http://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart
sudo service docker.io restart
newgrp docker

# install go-1.3.3
curl -O https://storage.googleapis.com/golang/go1.3.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.3.3.linux-amd64.tar.gz
rm go1.3.3.linux-amd64.tar.gz

sudo mkdir /data
sudo chown ubuntu:ubuntu /data

# env vriables
echo 'export GOROOT=/usr/local/go' | sudo tee --append /etc/bash.bashrc > /dev/null
echo 'export GOPATH=/data/go' | sudo tee --append /etc/bash.bashrc > /dev/null
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:$GOPATH/src/github.com/openshift/origin/_output/local/go/bin' | sudo tee --append /etc/bash.bashrc > /dev/null
echo 'export KUBECONFIG=$GOPATH/src/github.com/openshift/origin/openshift.local.certificates/admin/.kubeconfig' | sudo tee --append /etc/bash.bashrc > /dev/null

exec bash

# pull source code
mkdir -p $GOPATH/src/github.com/openshift/
cd $GOPATH/src/github.com/openshift/
git clone https://github.com/openshift/origin.git

cd $GOPATH/src/github.com/openshift/origin

# build
make clean build

# start 
sudo -s
mkdir -p logs/
nohup openshift start --public-master="https://ec2-52-4-51-219.compute-1.amazonaws.com:8443" > logs/out.log & 
exit

sudo tail -f logs/out.log

#manual: open https://ec2-52-4-51-219.compute-1.amazonaws.com:8443/console/


# open new shell window

cd $GOPATH/src/github.com/openshift/origin

# certs permission
sudo chmod +r openshift.local.certificates/admin/.kubeconfig
sudo chmod +r openshift.local.certificates/openshift-registry/.kubeconfig
sudo chmod +r openshift.local.certificates/openshift-router/.kubeconfig


openshift ex policy add-role-to-user view test-admin

# refresh https://localhost:8443/console/, you can see default project

openshift ex registry --create --credentials="openshift.local.certificates/openshift-registry/.kubeconfig"

# goto pods view, a docker-registry-1-30qpc pod is created here, and it is pending by pull the image

openshift ex router --create --credentials="openshift.local.certificates/openshift-router/.kubeconfig"

# goto pods view, a router-1-877md pod is created here, and it is pending by pull the image


# careate sample-app
openshift ex new-project test --display-name="OpenShift 3 Sample" --description="This is an example project to demonstrate OpenShift v3" --admin=test-admin
osc process -n test -f examples/sample-app/application-template-stibuild.json | osc create -n test -f -


# clean
sudo examples/sample-app/cleanup.sh
docker ps -a | awk '{ print $NF " " $1 }' | grep ^k8s_ | awk '{print $2}' |  xargs -l -r docker rm

