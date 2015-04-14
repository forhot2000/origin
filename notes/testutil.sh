#!/bin/bash

public_master="https://ec2-52-4-51-219.compute-1.amazonaws.com:8443"
project=""
user="test-admin"

alias openshift="_output/local/go/bin/openshift"
alias osc="_output/local/go/bin/osc"
# alias

function up
{
  sudo rm nohup.out
  sudo nohup _output/local/go/bin/openshift start --public-master="$public_master" &
  echo "listend on $public_master"
}

function init_certs
{
  echo "chmod certs"
  sudo chmod +r "openshift.local.certificates/admin/.kubeconfig"
  sudo chmod +r "openshift.local.certificates/openshift-registry/.kubeconfig"
  sudo chmod +r "openshift.local.certificates/openshift-router/.kubeconfig"
}

function init_users
{
  echo "add $user to view group"
  openshift ex policy add-role-to-user view "$user"
}

function logs
{
  echo "Press ^C to break."
  sudo tail -f nohup.out
}

function kill_proc
{
  sudo killall openshift
}

function clean
{
  sudo examples/sample-app/cleanup.sh
  docker ps -a | awk '{ print $NF " " $1 }' | grep ^k8s_ | awk '{print $2}' |  xargs -l -r docker rm
}

function start_miswhale
{
  openshift ex new-project miswhale --display-name="MisWhale" --description="Misfit MisWhale" --admin="$user"
  osc process -n miswhale -f miswhale-sti-template.json | osc create -n miswhale -f -
}

function rolling_update_miswhale
{
  echo "rolling update..."
}

function delete_miswhale
{
  osc process -n miswhale -f miswhale-sti-template.json | osc delete -n miswhale -f -
  osc delete pods --all -n miswhale
  osc delete builds --all -n miswhale
}

function start_ruby_sample
{
  openshift ex new-project test --display-name="OpenShift 3 Sample" --description="This is an example project to demonstrate OpenShift v3" --admin="$user"
  osc process -n test -f examples/sample-app/application-template-stibuild.json | osc create -n test -f -
}

function rolling_update_ruby_sample
{
  echo "rolling update..."
}

function delete_ruby_sample
{
  osc process -n test -f examples/sample-app/application-template-stibuild.json | osc delete -n test -f -
  osc delete pods --all -n test
  osc delete builds --all -n test
}

function start_registry
{
  openshift ex registry --create --credentials="openshift.local.certificates/openshift-registry/.kubeconfig"
}

function start_router
{
  openshift ex router --create --credentials="openshift.local.certificates/openshift-router/.kubeconfig"
}

function check_project_arg
{
  if [[ -z "$project" ]] ; then
    echo "require set -p option to specify project name."
    exit 1
  fi
}

function start_project
{
  check_project_arg
  case "$project" in
    "miswhale" ) start_miswhale;;
    "ruby-sample" ) start_ruby_sample;;
    "registry" ) start_registry;;
    "router" ) start_router;;
    * ) echo "unknow project: $project" && exit 1;
  esac
}

function rolling_update_project
{
  check_project_arg
  case "$project" in
    "miswhale" ) rolling_update_miswhale;;
    "ruby-sample" ) rolling_update_ruby_sample;;
    * ) echo "unknow project: $project" && exit 1;
  esac
}

function delete_project
{
  check_project_arg
  case "$project" in
    "miswhale" ) delete_miswhale;;
    "ruby-sample" ) delete_ruby_sample;;
    * ) echo "unknow project: $project" && exit 1;
  esac
}

function usage
{
  cat <<EOF
Usage: $0 [{options}] {action} [{action} ...]

action:
  up               start up openshift
  certs            add read permission to cert files
  users            add user to default group
  logs             rolling openshift logs
  kill             kill openshift
  clean            kill openshift and clean data
  start            start a project, require -p to specify project name
  help             show thie help text

options:
  -p {project}     sepcify project name
  -u {username}    specify username, default user is test-admin
EOF
}

# main

[[ $# = 0 ]] && usage && exit 1

while [[ $# > 0 ]]
do
  # echo "$1"
  case "$1" in
    "-p" ) shift && project="$1";;
    "-u" ) shift && user="$1";; 
    "up" ) up;;
    "certs" ) init_certs;;
    "users" ) init_users;;
    "logs" ) logs;;
    "kill" ) kill_proc;;
    "clean" ) clean;;
    "start" ) start_project;;
    "rollingupdate" ) rolling_update_project;;
    "delete" ) delete_project;;
    "help" ) usage;;
    * ) usage && exit 1;;
  esac
  shift
done
