#frontend-controller-v1.json
cat <<EOT > frontend-controller-v1.json
{
  "id": "frontend-controller-v1",
  "kind": "ReplicationController",
  "apiVersion": "v1beta1",
  "desiredState": {
    "replicas": 3,
    "replicaSelector": {
      "name": "frontend",
      "version": "v1"
    },
    "podTemplate": {
      "desiredState": {
         "manifest": {
           "version": "v1beta1",
           "id": "frontend",
           "containers": [{
             "name": "node-hello-fe",
             "image": "forhot2000/node-hello:latest",
             "ports": [{"name": "http-server", "containerPort": 8080}]
           }]
         }
       },
       "labels": {
         "name": "frontend",
         "version": "v1",
         "app": "frontend"
       }
      }},
  "labels": {"name": "frontend"}
}
EOT

#frontend-controller-v2.json
cat <<EOT > frontend-controller-v2.json
{
  "id": "frontend-controller-v2",
  "kind": "ReplicationController",
  "apiVersion": "v1beta1",
  "desiredState": {
    "replicas": 3,
    "replicaSelector": {
      "name": "frontend",
      "version": "v2"
    },
    "podTemplate": {
      "desiredState": {
         "manifest": {
           "version": "v1beta1",
           "id": "frontend",
           "containers": [{
             "name": "node-hello-fe",
             "image": "forhot2000/node-hello:beta",
             "ports": [{"name": "http-server", "containerPort": 8080}]
           }]
         }
       },
       "labels": {
         "name": "frontend",
         "version": "v2",
         "app": "frontend"
       }
      }},
  "labels": {"name": "frontend"}
}
EOT

#frontend-service.json
cat <<EOT > frontend-service.json
{
  "id": "frontend",
  "kind": "Service",
  "apiVersion": "v1beta1",
  "port": 8000,
  "containerPort": "http-server",
  "selector": {
    "name": "frontend"
  },
  "labels": {
    "name": "frontend"
  }
}
EOT

openshift kube create -f frontend-controller-v1.json -n test2

openshift kube create -f frontend-service.json -n test2

openshift kube rollingupdate frontend-controller-v1 --poll-interval='3s' -f frontend-controller-v2.json -n test2
openshift kube rollingupdate frontend-controller-v2 --poll-interval='3s' -f frontend-controller-v1.json -n test2

openshift kube get rc -n test2

watch -n 1 openshift kube get pods -n test2

openshift kube stop rc frontend-controller -n test2

