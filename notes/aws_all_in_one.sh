#!/bin/bash

# requirements
sudo apt-get install -y git make gcc

# install docker
wget -qO- https://get.docker.com/ | sh

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
echo 'export GOROOT=/usr/local/go' >> ~/.bash_profile
echo 'export GOPATH=/data/go' >> ~/.bash_profile
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:$GOPATH/src/github.com/openshift/origin/_output/local/go/bin' >> ~/.bash_profile
echo 'export KUBECONFIG=$GOPATH/src/github.com/openshift/origin/openshift.local.certificates/admin/.kubeconfig' >> ~/.bash_profile

echo "alias grep='grep --color=auto'" >> ~/.bash_profile
echo "alias l='ls -CF --color=auto'" >> ~/.bash_profile
echo "alias la='ls -A --color=auto'" >> ~/.bash_profile
echo "alias ls='ls --color=auto'" >> ~/.bash_profile
echo "alias ll='ls -alF --color=auto'" >> ~/.bash_profile

. ~/.bash_profile

# pull source code
mkdir -p $GOPATH/src/github.com/openshift/
cd $GOPATH/src/github.com/openshift/
git clone https://github.com/openshift/origin.git

cd $GOPATH/src/github.com/openshift/origin
sudo chmod +r openshift.local.certificates/admin/.kubeconfig
sudo chmod +r openshift.local.certificates/openshift-registry/.kubeconfig
sudo chmod +r openshift.local.certificates/openshift-router/.kubeconfig

# build
make clean build

# start 
openshift start --public-master="https://ec2-52-4-51-219.compute-1.amazonaws.com:8443"

#manual: open https://ec2-52-4-51-219.compute-1.amazonaws.com:8443/console/

openshift ex policy add-role-to-user view test-admin

# refresh https://localhost:8443/console/, you can see default project

openshift ex registry --create --credentials="openshift.local.certificates/openshift-registry/.kubeconfig"

# goto pods view, a docker-registry-1-30qpc pod is created here, and it is pending by pull the image

openshift ex router --create --credentials="openshift.local.certificates/openshift-router/.kubeconfig"

# goto pods view, a router-1-877md pod is created here, and it is pending by pull the image

cd $GOPATH/src/github.com/openshift/origin/examples/sample-app
openshift ex new-project test --display-name="OpenShift 3 Sample" --description="This is an example project to demonstrate OpenShift v3" --admin=test-admin
osc process -n test -f application-template-stibuild.json | osc create -n test -f -

